#' Applies a Function on Each Chunk of a File-Backed Matrix.
#'
#' Similar to [base::lapply()], but designed for file-backed matrices. The
#' function brings chunks of an object into physical memory by taking subsets,
#' and applies a function on them. If `nCores` is greater than 1, the function
#' will be applied in parallel using [parallel::mclapply()]. In that case the
#' subsets of the object are taken on the slaves.
#'
#' @inheritSection BGData-package File-backed matrices
#' @inheritSection BGData-package Multi-level parallelism
#' @param X A file-backed matrix, typically `@@geno` of a [BGData-class]
#' object.
#' @param FUN The function to be applied on each chunk.
#' @param i Indicates which rows of `X` should be used. Can be integer,
#' boolean, or character. By default, all rows are used.
#' @param j Indicates which columns of `X` should be used. Can be integer,
#' boolean, or character. By default, all columns are used.
#' @param chunkBy Whether to extract chunks by rows (1) or by columns (2).
#' Defaults to columns (2).
#' @param chunkSize The number of rows or columns of `X` that are brought into
#' physical memory for processing per core. If `NULL`, all elements in `i` or
#' `j` are used. Defaults to 5000.
#' @param nCores The number of cores (passed to [parallel::mclapply()]).
#' Defaults to the number of cores as detected by [parallel::detectCores()].
#' @param verbose Whether progress updates will be posted. Defaults to `FALSE`.
#' @param ... Additional arguments to be passed to the [base::apply()] like
#' function.
#' @example man/examples/chunkedMap.R
#' @export
chunkedMap <- function(X, FUN, i = seq_len(nrow(X)), j = seq_len(ncol(X)), chunkBy = 2L, chunkSize = 5000L, nCores = getOption("mc.cores", 2L), verbose = FALSE, ...) {
    if (length(dim(X)) != 2L) {
        stop("X must be a matrix-like object")
    }
    i <- crochet::convertIndex(X, i, "i")
    j <- crochet::convertIndex(X, j, "j")
    dim <- c(length(i), length(j))
    if (is.null(chunkSize)) {
        chunkSize <- dim[chunkBy]
        nChunks <- 1L
    } else {
        nChunks <- ceiling(dim[chunkBy] / chunkSize)
    }
    chunkApply <- function(curChunk, ...) {
        if (verbose) {
            if (nCores > 1) {
                message("Process ", Sys.getpid(), ": Chunk ", curChunk, " of ", nChunks, " ...")
            } else {
                message("Chunk ", curChunk, " of ", nChunks, " ...")
            }
        }
        range <- seq(
            ((curChunk - 1L) * chunkSize) + 1L,
            min(curChunk * chunkSize, dim[chunkBy])
        )
        if (chunkBy == 2L) {
            chunk <- X[i, j[range], drop = FALSE]
        } else {
            chunk <- X[i[range], j, drop = FALSE]
        }
        FUN(chunk, ...)
    }
    if (nCores == 1L) {
        res <- lapply(X = seq_len(nChunks), FUN = chunkApply, ...)
    } else {
        # Suppress warnings because we are handling errors ourselves
        res <- suppressWarnings(parallel::mclapply(X = seq_len(nChunks), FUN = chunkApply, ..., mc.cores = nCores)) #
        errors <- which(sapply(res, class) == "try-error")
        if (length(errors) > 0L) {
            # With mc.preschedule = TRUE (the default), if a job fails, the
            # remaining jobs will fail as well with the same error message.
            # Therefore, the number of errors does not tell how many errors
            # actually occurred and we forward only the first error message.
            errorMessage <- attr(res[[errors[1L]]], "condition")$message
            stop("in chunk ", errors[1L], " (only first error is shown)", ": ", errorMessage, call. = FALSE)
        }
    }
    return(res)
}


#' Applies a Function on Each Row or Column of a File-Backed Matrix.
#'
#' Similar to [base::apply()], but designed for file-backed matrices. The
#' function brings chunks of an object into physical memory by taking subsets,
#' and applies a function on either the rows or the columns of the chunks using
#' an optimized version of [base::apply()]. If `nCores` is greater than 1, the
#' function will be applied in parallel using [parallel::mclapply()]. In that
#' case the subsets of the object are taken on the slaves.
#'
#' @inheritSection BGData-package File-backed matrices
#' @inheritSection BGData-package Multi-level parallelism
#' @param X A file-backed matrix, typically `@@geno` of a [BGData-class]
#' object.
#' @param MARGIN The subscripts which the function will be applied over. 1
#' indicates rows, 2 indicates columns.
#' @param FUN The function to be applied.
#' @param i Indicates which rows of `X` should be used. Can be integer,
#' boolean, or character. By default, all rows are used.
#' @param j Indicates which columns of `X` should be used. Can be integer,
#' boolean, or character. By default, all columns are used.
#' @param chunkSize The number of rows or columns of `X` that are brought into
#' physical memory for processing per core. If `NULL`, all elements in `i` or
#' `j` are used. Defaults to 5000.
#' @param nCores The number of cores (passed to [parallel::mclapply()]).
#' Defaults to the number of cores as detected by [parallel::detectCores()].
#' @param verbose Whether progress updates will be posted. Defaults to `FALSE`.
#' @param ... Additional arguments to be passed to the [base::apply()] like
#' function.
#' @example man/examples/chunkedApply.R
#' @export
chunkedApply <- function(X, MARGIN, FUN, i = seq_len(nrow(X)), j = seq_len(ncol(X)), chunkSize = 5000L, nCores = getOption("mc.cores", 2L), verbose = FALSE, ...) {
    res <- chunkedMap(X = X, FUN = function(chunk, ...) {
        apply2(X = chunk, MARGIN = MARGIN, FUN = FUN, ...)
    }, i = i, j = j, chunkBy = MARGIN, chunkSize = chunkSize, nCores = nCores, verbose = verbose, ...)
    simplifyList(res)
}


# A more memory-efficient version of apply.
#
# apply always makes a copy of the data.
apply2 <- function(X, MARGIN, FUN, ...) {
    d <- dim(X)
    if (MARGIN == 1L) {
        subset <- X[1L, ]
    } else {
        subset <- X[, 1L]
    }
    sample <- FUN(subset, ...)
    if (is.table(sample)) {
        stop("tables are not supported.")
    } else if (is.list(sample)) {
        # List
        OUT <- vector(mode = "list", length = d[MARGIN])
        names(OUT) <- dimnames(X)[[MARGIN]]
        OUT[[1L]] <- sample
        if (d[MARGIN] > 1L) {
            for (i in seq(2L, d[MARGIN])) {
                if (MARGIN == 1L) {
                    subset <- X[i, ]
                } else {
                    subset <- X[, i]
                }
                OUT[[i]] <- FUN(subset, ...)
            }
        }
    } else {
        if (length(sample) > 1L) {
            # Matrix or atomic vector of length > 1
            OUT <- matrix(data = normalizeType(typeof(sample)), nrow = length(sample), ncol = d[MARGIN])
            if (!is.matrix(sample) && !is.null(names(sample))) {
                if (MARGIN == 1L) {
                    dimnames(OUT) <- list(NULL, names(sample))
                } else {
                    dimnames(OUT) <- list(names(sample), NULL)
                }
            }
            OUT[, 1L] <- sample
            if (d[MARGIN] > 1L) {
                for (i in seq(2L, d[MARGIN])) {
                    if (MARGIN == 1L) {
                        subset <- X[i, ]
                    } else {
                        subset <- X[, i]
                    }
                    OUT[, i] <- FUN(subset, ...)
                }
            }
        } else {
            # Atomic vector of length 1
            OUT <- vector(mode = typeof(sample), length = d[MARGIN])
            names(OUT) <- dimnames(X)[[MARGIN]]
            OUT[1L] <- sample
            if (d[MARGIN] > 1L) {
                for (i in seq(2L, d[MARGIN])) {
                    if (MARGIN == 1L) {
                        subset <- X[i, ]
                    } else {
                        subset <- X[, i]
                    }
                    OUT[i] <- FUN(subset, ...)
                }
            }
        }
    }
    return(OUT)
}


simplifyList <- function(x) {
    sample <- x[[1L]]
    if (is.matrix(sample)) {
        x <- matrix(data = unlist(x), nrow = nrow(sample), byrow = FALSE)
        rownames(x) <- rownames(sample)
    } else {
        x <- unlist(x)
    }
    return(x)
}
