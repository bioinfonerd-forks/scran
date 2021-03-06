\name{convertTo}
\alias{convertTo}
\alias{convertTo,SingleCellExperiment-method}

\title{Convert to other classes}
\description{
Convert a SingleCellExperiment object into other classes for entry into other analysis pipelines.
}

\usage{
\S4method{convertTo}{SingleCellExperiment}(x, type=c("edgeR", "DESeq2", "monocle"),
    row.fields=NULL, col.fields=NULL, ..., assay.type, 
    use.all.sf=TRUE, subset.row=NULL, get.spikes=FALSE)
}

\arguments{
\item{x}{A SingleCellExperiment object.}
\item{type}{A string specifying the analysis for which the object should be prepared.}
\item{row.fields}{Any set of indices specifying which columns of \code{rowData(x)} should be retained in the returned object.}
\item{col.fields}{Any set of indices specifying which columns of \code{colData(x)} should be retained.}
\item{...}{Other arguments to be passed to pipeline-specific constructors.}
\item{assay.type}{A string specifying which assay of \code{x} should be put in the returned object.}
\item{use.all.sf}{A logical scalar indicating whether multiple size factors should be used to generate the returned object.}
\item{subset.row, get.spikes}{See \code{?"\link{scran-gene-selection}"}.}

}

\value{
For \code{type="edgeR"}, a DGEList object is returned containing the count matrix.
Size factors are converted to normalization factors.
Gene-specific \code{rowData} is stored in the \code{genes} element, and cell-specific \code{colData} is stored in the \code{samples} element.

For \code{type="DESeq2"}, a DESeqDataSet object is returned containing the count matrix and size factors.
Additional gene- and cell-specific data is stored in the \code{mcols} and \code{colData} respectively.

For \code{type="monocle"}, a CellDataSet object is returned containing the count matrix and size factors.
Additional gene- and cell-specific data is stored in the \code{rowData} and \code{colData} respectively.
}

\details{
This function converts an SingleCellExperiment object into various other classes in preparation for entry into other analysis pipelines, as specified by \code{type}.
Gene- and cell-specific data fields can be retained in the output object by setting \code{row.fields} and \code{col.fields}, respectively.
Other arguments can be passed to the relevant constructors through the ellipsis.

By default, \code{assay.type} is set to \code{"counts"} such that count data is stored in the output object.
This is consistent with the required inputs to analyses using count-based (e.g., negative binomial) models. 
Information about normalization is instead transmitted via size or normalization factors in the output object.

In all cases, rows corresponding to spike-in transcripts are removed from the output object by default.
As such, rows in the returned object may not correspond directly to rows in \code{x}.
Users should consider this when retrieving analysis results from these pipelines, e.g., match on row names in \code{x} before comparing to other results.
This behaviour can be turned off by setting \code{get.spikes=TRUE}.

For \pkg{edgeR} and \pkg{DESeq2}, different size factors for different rows (e.g., for spike-in sets) will be respected.
For \pkg{edgeR}, an offset matrix will be constructed containing mean-centred log-size factors for each row.
For \pkg{DESeq2}, a similar matrix will be constructed containing size factors scaled to have a geometric mean of unity.
This behaviour can be turned off with \code{use.all.sf=FALSE}, such that only \code{sizeFactors(x)} is used for normalization for all \code{type}.
(These matrices are not generated if all rows correspond to \code{sizeFactors(x)}, as this information is already stored in the object.)
}

\author{
Aaron Lun
}

\seealso{
\code{\link[edgeR]{DGEList}},
\code{\link[DESeq2:DESeqDataSet]{DESeqDataSetFromMatrix}},
\code{\link[monocle]{newCellDataSet}}
}

\examples{
example(computeSpikeFactors) # Using the mocked up data 'y' from this example.
sizeFactors(y) <- 2^rnorm(ncells) # Adding some additional embellishments.
rowData(y)$SYMBOL <- paste0("X", seq_len(nrow(y)))
y$other <- sample(LETTERS, ncells, replace=TRUE)

# Converting to various objects.
convertTo(y, type="edgeR")
convertTo(y, type="DESeq2")
convertTo(y, type="monocle")
}

