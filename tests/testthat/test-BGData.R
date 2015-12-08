context("BGData")

# Create temporary directory
tmpPath <- paste0("/tmp/BGData-", randomString(), "/")
dir.create(tmpPath)

restoreGenotypes <- function() {
    genotypes <- matrix(c(4, 4, 4, 3, 2, 3, 1, 2, 1), nrow = nRows, ncol = nCols)
    colnames(genotypes) <- paste0("mrk_", 1:3)
    rownames(genotypes) <- paste0("1_", 1:3)
    return(genotypes)
}

# Create example PED files
pedPath <- paste0(tmpPath, "ped-", randomString(), ".txt")
nRows <- 3
nCols <- 3
phenotypes <- data.frame(FID = c("1", "1", "1"), IID = c("1", "2", "3"), 
    PAT = c("NA", "NA", "NA"), MAT = c("NA", "NA", "NA"), SEX = c("NA", "NA", "NA"), 
    PHENOTYPE = c("NA", "NA", "NA"), stringsAsFactors = FALSE)
phenotypes[] <- lapply(phenotypes, type.convert, as.is = TRUE)
rownames(phenotypes) <- paste0("1_", 1:3)
genotypes <- restoreGenotypes()
ped <- cbind(phenotypes, genotypes)
outFile <- file(pedPath, "w")
outGzFile <- gzfile(paste0(pedPath, ".gz"), "w")
write.table(ped, file = outFile, quote = FALSE, row.names = FALSE)
write.table(ped, file = outGzFile, quote = FALSE, row.names = FALSE)
close(outFile)
close(outGzFile)


context("readPED")

test_that("it complains if folderOut already exists", {
    dirExistsPath <- paste0(tmpPath, "dirExists")
    dir.create(dirExistsPath, showWarnings = FALSE)
    expect_error(readPED(fileIn = pedPath, header = TRUE, dataType = "integer", n = nRows, folderOut = dirExistsPath))
})


test_that("it reads PED files into BGData objects", {

    for (ext in c("", ".gz")) {

        adjPedPath <- paste0(pedPath, ext)

        # With minimum number of parameters (with exception of folderOut)
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = integer(), folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With n
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = integer(), n = nRows, folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With p
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = integer(), p = nCols, folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With both n and p
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = integer(), n = nRows, p = nCols, folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # As integer
        class(genotypes) <- "integer"
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = integer(), folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = "integer", folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

        # As double
        class(genotypes) <- "double"
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = double(), folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED(fileIn = adjPedPath, header = TRUE, dataType = "double", folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

        # As character
        expect_error(readPED(fileIn = adjPedPath, header = TRUE, dataType = character(), folderOut = paste0(tmpPath, "test-", randomString())))
        expect_error(readPED(fileIn = adjPedPath, header = TRUE, dataType = "character", folderOut = paste0(tmpPath, "test-", randomString())))
    }

})


context("readPED.matrix")

test_that("it reads a PED file into a matrix object", {

    for (ext in c("", ".gz")) {

        adjPedPath <- paste0(pedPath, ext)

        # With minimum number of parameters (with exception of folderOut)
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer())
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With n
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), n = nRows)
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With p
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), p = nCols)
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With both n and p
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), n = nRows, p = nCols)
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # As integer
        class(genotypes) <- "integer"
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer())
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = "integer")
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

        # As double
        class(genotypes) <- "double"
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = double())
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = "double")
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

        # As character
        class(genotypes) <- "character"
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = character())
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED.matrix(fileIn = adjPedPath, header = TRUE, dataType = "character")
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

    }

})

context("readPED.big.matrix")

test_that("it reads a PED file into a big.matrix object", {

    for (ext in c("", ".gz")) {

        adjPedPath <- paste0(pedPath, ext)

        # With minimum number of parameters (with exception of folderOut)
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With n
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), n = nRows, folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With p
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), p = nCols, folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # With both n and p
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), n = nRows, p = nCols, folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@pheno, phenotypes)
        expect_equal(BGData@geno[], genotypes)

        # As integer
        class(genotypes) <- "integer"
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = integer(), folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = "integer", folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

        # As double
        class(genotypes) <- "double"
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = double(), folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        BGData <- readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = "double", folderOut = paste0(tmpPath, "test-", randomString()))
        expect_equal(BGData@geno[], genotypes)
        genotypes <- restoreGenotypes()

        # As character
        class(genotypes) <- "character"
        expect_error(readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = character(), folderOut = paste0(tmpPath, "test-", randomString())))
        expect_error(readPED.big.matrix(fileIn = adjPedPath, header = TRUE, dataType = "character", folderOut = paste0(tmpPath, "test-", randomString())))
        genotypes <- restoreGenotypes()

    }

})

context("load.BGData")

test_that("it loads BGData objects created by readPED", {

    # Create dummy BGData object without returning data
    path <- paste0(tmpPath, "test-", randomString())
    readPED(fileIn = pedPath, header = TRUE, dataType = integer(), folderOut = path)
    expect_true(!("BGData" %in% ls()))

    # Append BGData.RData to path
    path <- paste0(path, "/", "BGData.RData")

    # Load BGData object and test if all nodes have been opened
    load.BGData(path)
    expect_true("BGData" %in% ls())
    for (node in seq_len(LinkedMatrix::nNodes(BGData@geno))) {
        expect_true(ff::is.open(BGData@geno[[node]]))
    }
    expect_equal(dim(BGData@geno), c(nRows, nCols))

})

test_that("it loads BGData objects created by readPED.matrix", {

    # Create dummy BGData object
    path <- paste0(tmpPath, "test-", randomString(), "/", "BGData.RData")
    dir.create(dirname(path))
    BGData <- readPED.matrix(fileIn = pedPath, header = TRUE, dataType = integer())
    save(BGData, file = path)
    rm(BGData)
    expect_true(!("BGData" %in% ls()))

    # Load BGData object
    load.BGData(path)
    expect_true("BGData" %in% ls())
    expect_equal(dim(BGData@geno), c(nRows, nCols))

})

test_that("it loads BGData objects created by readPED.big.matrix", {

    # Create dummy BGData object
    path <- paste0(tmpPath, "test-", randomString())
    readPED.big.matrix(fileIn = pedPath, header = TRUE, dataType = integer(), folderOut = path)
    expect_true(!("BGData" %in% ls()))

    # Append BGData.RData to path
    path <- paste0(path, "/", "BGData.RData")

    # Load BGData object
    load.BGData(path)
    expect_true("BGData" %in% ls())
    expect_equal(dim(BGData@geno), c(nRows, nCols))

})