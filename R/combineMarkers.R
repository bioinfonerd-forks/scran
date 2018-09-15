#' @export
#' @importFrom S4Vectors DataFrame
#' @importClassesFrom S4Vectors DataFrame List
#' @importFrom stats p.adjust
#' @importFrom BiocGenerics cbind
#' @importFrom methods as
combineMarkers <- function(de.lists, pairs, pval.field="p.value", effect.field="logFC", 
    pval.type=c("any", "all"), log.p.in=FALSE, log.p.out=log.p.in, 
    output.field=NULL, full.stats=FALSE)
# Combines pairwise DE into a single marker list for each group,
# with associated statistics.
# 
# written by Aaron Lun
# created 13 September 2018
{
    if (length(de.lists)!=nrow(pairs)) {
        stop("'nrow(pairs)' must be equal to 'length(de.lists)'")
    }
    if (is.null(output.field)) {
        output.field <- if (full.stats) "stats" else effect.field
    }
    pval.type <- match.arg(pval.type)

    # Checking that all genes are the same across lists.
    gene.names <- NULL
    for (x in seq_along(de.lists)) {
        current <- de.lists[[x]]
        curnames <- rownames(current)

        if (is.null(gene.names)) {
            gene.names <- curnames
        } else if (!identical(gene.names, curnames)) {
            stop("row names should be the same for all elements of 'de.lists'")
        }
    }

    # Processing by the first element of each pair.
    by.first <- split(seq_along(de.lists), pairs[,1], drop=TRUE)
    output <- vector("list", length(by.first))
    names(output) <- names(by.first)

    for (host in names(by.first)) {
        chosen <- by.first[[host]]
        targets <- pairs[chosen, 2]
        cur.stats <- de.lists[by.first[[host]]]

        target.o <- order(targets)
        target.o <- target.o[!is.na(targets[target.o])]
        targets <- targets[target.o]
        cur.stats <- cur.stats[target.o]

        all.p <- lapply(cur.stats, "[[", i=pval.field)
        all.p <- do.call(cbind, all.p)
        pval <- .combine_pvalues(all.p, pval.type=pval.type, log.p.in=log.p.in, log.p.out=log.p.out)
        preamble <- DataFrame(row.names=gene.names)

        # Determining rank.
        if (pval.type=="any") {
            rank.out <- .rank_top_genes(all.p)
            min.rank <- rank.out$rank
            min.p <- rank.out$value
            gene.order <- order(min.rank, min.p)
            preamble$Top <- min.rank
        } else {
            gene.order <- order(pval)
        }

        # Correcting for multiple testing.
        if (log.p.out) {
            corrected <- .logBH(pval)
        } else {
            corrected <- p.adjust(pval, method="BH")
        }
        
        prefix <- if (log.p.out) "log." else ""
        preamble[[paste0(prefix, "p.value")]] <- pval 
        preamble[[paste0(prefix, "FDR")]] <- corrected 

        # Saving effect sizes or all statistics.
        if (full.stats) {
            cur.stats <- lapply(cur.stats, FUN=function(x) { I(as(x, Class="DataFrame")) })
            stat.df <- do.call(DataFrame, c(cur.stats, list(check.names=FALSE)))
        } else {
            all.effects <- lapply(cur.stats, "[[", i=effect.field)
            stat.df <- DataFrame(all.effects)
        }
        colnames(stat.df) <- sprintf("%s.%s", output.field, targets)

        # Producing the output object.
        marker.set <- cbind(preamble, stat.df)
        marker.set <- marker.set[gene.order,,drop=FALSE]
        output[[host]] <- marker.set
    }

    return(as(output, "List"))
}