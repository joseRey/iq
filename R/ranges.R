#' Sample index at the given time instant
#'
#' @param time Time instant.
#' @param sample.rate Sample rate of the signal.
#'
#' @return A sample index at the given time instant.
SampleIndexAtTime <- function(time, sample.rate) {
  sample.index <- trunc(time * sample.rate) + 1
  return(sample.index)
}

#' Time corresponding to the beginning of the given sample
#'
#' @param sample.index Index of the sample.
#' @param sample.rate Sample rate of the signal.
#'
#' @return A time corresponding to the beginning of the given sample.
TimeAtSampleIndex <- function(sample.index, sample.rate) {
  time <- (sample.index - 1) / sample.rate
  return(time)
}

#' Extract a range of sample indexes
#'
#' Sample indices take precedence over times whereas the maximum number of
#' samples take precedence over the sample rate. When boudaries are omitted
#' (\code{NA}) then the boundaries of the signal are used. If \code{max.samples}
#' is \code{NA} all the sample indices in the range are returned.
#'
#' @param signal Source signal
#' @param first.sample.index First sample index.
#' @param last.sample.index Last sample index.
#' @param from.time Time of the first sample.
#' @param to.time Time of the last sample.
#' @param max.samples Maximum number of returned sample indices.
#' @param sample.rate New sample rate.
#'
#' @return A vector containing at most \code{max.samples} sample indices from
#'   the given range.
SampleIndexRange <- function(signal, first.sample.index = NA, last.sample.index = NA,
                             from.time = NA, to.time = NA, max.samples = NA, sample.rate = NA) {
  # convert and use dafault values
  if (is.na(first.sample.index)) {
    if (is.na(from.time)) {
      first.sample.index <- 1
    } else {
      first.sample.index <- SampleIndexAtTime(from.time, signal$sample.rate)
    }
  }
  if (is.na(last.sample.index)) {
    if (is.na(to.time)) {
      last.sample.index <- signal$n.samples
    } else {
      last.sample.index <- SampleIndexAtTime(to.time, signal$sample.rate)
    }
  }
  samples.between <- last.sample.index - first.sample.index + 1
  if (is.na(max.samples)) {
    if (is.na(sample.rate)) {
      max.samples <- Inf
    } else {
      new.duration <- samples.between / signal$sample.rate
      max.samples <- trunc(sample.rate * new.duration)
    }
  }
  # compute the new sample index range
  sample.index.range <- round(seq.int(first.sample.index, last.sample.index,
                                      length.out=min(samples.between, max.samples)))
  return(sample.index.range)
}

#' Extract a range of the signal
#'
#' Samples outside the signal range are assumed to be zero. Range parameters are
#' interpreted by \code{\link{SampleIndexRange}}.
#'
#' @inheritParams SampleIndexRange
#'
#' @return A named list containing two items: \code{time} and \code{iq}.
#'
#' @export
SampleRange <- function(signal, first.sample.index = NA, last.sample.index = NA,
                        from.time = NA, to.time = NA, max.samples = NA, sample.rate = NA) {
  # compute the sample index range
  sample.index.range <- SampleIndexRange(signal, first.sample.index, last.sample.index,
                                         from.time, to.time, max.samples, sample.rate)
  # compute the time range
  time <- TimeAtSampleIndex(sample.index.range, signal$sample.rate)
  # normalize and convert samples to complex numbers defaulting to zero for the
  # values outside the signal sample range
  valid.range <- sample.index.range > 0 & sample.index.range <= signal$n.samples
  i.indices <- sample.index.range[valid.range] * 2 - 1
  q.indices <- sample.index.range[valid.range] * 2
  i <- numeric(length(sample.index.range))
  q <- numeric(length(sample.index.range))
  i[valid.range] <- NormalizeRawSamples(signal$raw.vector[i.indices])
  q[valid.range] <- NormalizeRawSamples(signal$raw.vector[q.indices])
  iq <- complex(real = i, imaginary = q)
  # prepare the resulting data frame
  range <- data.frame(time, iq)
  return(range)
}
