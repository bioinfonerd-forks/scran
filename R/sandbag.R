find.markers <- function(current.data, other.data, gene.names, fraction=0.5)
# This identifies pairs of genes whose relative expression is > 0 in 
# at least a 'fraction' of cells in one phase is < 0 in at least 
# 'fraction' of the cells in each of the other phases.
{
    Ngenes <- ncol(current.data)
    if (length(gene.names)!=Ngenes) {
        stop("length of 'gene.names' vector must be equal to 'x' nrows")
    }
    other.Ngenes <- vapply(other.data, ncol, FUN.VALUE=0L)
    if (any(other.Ngenes!=Ngenes)) { 
        stop("number of genes in each class must be the same")
    }
    Ncells <- nrow(current.data)
    other.Ncells <- vapply(other.data, nrow, FUN.VALUE=0L)
    if (Ncells==0L || any(other.Ncells==0L)) {
        stop("each class must have at least one cell")
    }

    # Calculating thresholds.
    Nthr.cur <- ceiling(Ncells * fraction)
    Nthr.other <- ceiling(other.Ncells * fraction)

    if (Ngenes) { 
        collected <- vector("list", Ngenes*2)
        collected[[1]] <- matrix(0L, 0, 2)

        for (i in seq_len(Ngenes-1L)) { 
            others <- (i+1):Ngenes
            cur.diff <- current.data[,i] - current.data[,others,drop=FALSE]
            other.diff <- lapply(other.data, function(odata) { odata[,i] - odata[,others,drop=FALSE] })

            # Looking for marker pairs that are up in the current group and down in the other groups.
            cur.pos.above.threshold <- colSums(cur.diff > 0) >= Nthr.cur
            other.neg.above.threshold <- mapply(function(odata, thr) { colSums(odata < 0) >= thr}, 
                                                other.diff, Nthr.other, SIMPLIFY=FALSE, USE.NAMES=FALSE)
            chosen <- others[cur.pos.above.threshold & Reduce(`&`, other.neg.above.threshold)]
            if (length(chosen)) { 
                collected[[i*2]] <- cbind(i, chosen)
            }

            # Looking for marker pairs that are down in the current group and up in the other groups.
            cur.neg.above.threshold <- colSums(cur.diff < 0) >= Nthr.cur
            other.pos.above.threshold <- mapply(function(odata, thr) { colSums(odata > 0) >= thr}, 
                                                other.diff, Nthr.other, SIMPLIFY=FALSE, USE.NAMES=FALSE)
            chosen.flip <- others[cur.neg.above.threshold & Reduce(`&`, other.pos.above.threshold)]
            if (length(chosen.flip)) { 
                collected[[i*2+1]] <- cbind(chosen.flip, i)
            }
        }

        collected <- do.call(rbind, collected)
        g1 <- gene.names[collected[,1]]
        g2 <- gene.names[collected[,2]]
    } else {
        g1 <- g2 <- character(0)
    }

    return(data.frame(first=g1, second=g2, stringsAsFactors=FALSE))
}

#' @export
setGeneric("sandbag", function(x, ...) standardGeneric("sandbag"))

#' @export
setMethod("sandbag", "ANY", function(x, phases, gene.names=rownames(x), fraction=0.5, subset.row=NULL) 
# Identifies the relevant pairs before running 'cyclone'.
# Basically runs through all combinations of 'find.markers' for each phase. 
#
# written by Aaron Lun
# based on code by Antonio Scialdone
# created 22 January 2016 
{
    subset.row <- .subset_to_index(subset.row, x, byrow=TRUE)
    gene.names <- gene.names[subset.row]

    class.names <- names(phases)
    if (is.null(class.names) || is.na(class.names)) stop("'phases' must have non-missing, non-NULL names") 
    gene.data <- lapply(phases, function(cl) t(x[subset.row,cl,drop=FALSE]))

    nclasses <- length(gene.data)
    marker.pairs <- vector("list", nclasses)
    for (i in seq_len(nclasses)) {
        marker.pairs[[i]] <- find.markers(gene.data[[i]], gene.data[-i], fraction=fraction, gene.names=gene.names)
    }

    names(marker.pairs) <- class.names
    return(marker.pairs)
})

#' @importFrom SummarizedExperiment assay
setMethod("sandbag", "SingleCellExperiment", 
          function(x, phases, subset.row=NULL, ..., assay.type="counts", get.spikes=FALSE) {

    subset.row <- .SCE_subset_genes(subset.row=subset.row, x=x, get.spikes=get.spikes)
    sandbag(assay(x, i=assay.type), phases=phases, ..., subset.row=subset.row)
})
