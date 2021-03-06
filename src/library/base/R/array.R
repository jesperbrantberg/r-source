#  File src/library/base/R/array.R
#  Part of the R package, https://www.R-project.org
#
#  Copyright (C) 1995-2015 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  https://www.R-project.org/Licenses/

array <-
function(data = NA, dim = length(data), dimnames = NULL)
{
    ## allow for as.vector.factor (converts to character)
    if(is.atomic(data) && !is.object(data))
        return(.Internal(array(data, dim, dimnames)))
    data <- as.vector(data)
    ## package rv has an as.vector() method which leave this as a classed list
    if(is.object(data)) {
        dim <- as.integer(dim)
        if (!length(dim)) stop("'dims' cannot be of length 0")
        vl <- prod(dim)
        if(length(data) != vl) {
            ## C code allows long vectors, but rep() does not.
            if(vl > .Machine$integer.max)
                stop("'dim' specifies too large an array")
            data <- rep_len(data, vl)
        }
        if(length(dim)) dim(data) <- dim
        if(is.list(dimnames) && length(dimnames)) dimnames(data) <- dimnames
        data
    } else .Internal(array(data, dim, dimnames))
}

slice.index <-
function(x, MARGIN)
{
    d <- dim(x)
    if(is.null(d))
        d <- length(x)
    n <- length(d)

    if(!length(MARGIN) || any(MARGIN < 1L) || any(MARGIN > n))
        stop("incorrect value for 'MARGIN'")

    if(any(d == 0L)) return(array(integer(), d))

    m <- MARGIN[1L]
    y <- rep.int(rep.int(1L:d[m],
                         prod(d[seq_len(m - 1L)]) *
                         rep.int(1L, d[m])),
                 prod(d[seq.int(from = m + 1L,
                                length.out = n - m)]))
    if(length(MARGIN) > 1L) {
        p <- d[m]
        for(m in MARGIN[-1L]) {
            y <- y + p * rep.int(rep.int(seq.int(0L, d[m] - 1L),
                                         prod(d[seq_len(m - 1L)]) *
                                         rep.int(1L, d[m])),
                                 prod(d[seq.int(from = m + 1L,
                                                length.out = n - m)]))
            p <- p * d[m]
        }
    }

    dim(y) <- d
    y
}

provideDimnames <-
function(x, sep = "", base = list(LETTERS), unique = TRUE)
{
    ## provide dimnames where missing - not copying x unnecessarily
    dx <- dim(x)
    dnx <- dimnames(x)
    if(new <- is.null(dnx))
	dnx <- vector("list", length(dx))
    k <- length(M <- lengths(base))
    for(i in which(vapply(dnx, is.null, NA))) {
	ii <- 1L+(i-1L) %% k # recycling
        ss <- seq_len(dx[i]) - 1L # dim could be zero
	bi <- base[[ii]][1L+ (ss %% M[ii])]
	dnx[[i]] <- if(unique) make.unique(bi, sep = sep) else bi
	new <- TRUE
    }
    if(new) dimnames(x) <- dnx
    x
}
