# Climate-based scaling of dung decay rates -----------------------------------
#
# The package's decay rates were measured at a single Central Florida site in
# summer. To estimate decay elsewhere we scale those rates by how the local
# climate differs from that reference, using two WorldClim "bioclim" variables
# that match the summer collection window:
#
#   BIO10 - mean temperature of the warmest quarter (deg C)
#   BIO18 - precipitation of the warmest quarter (mm)
#
# Temperature acts through a Q10 response (a standard description of how
# biological decomposition speeds up with warmth); moisture acts through a
# saturating multiplier (decomposition rises with rainfall but with diminishing
# returns). Both factors are normalised to equal 1 at the reference climate, so
# the model reproduces the measured rates exactly at the Florida site.
#
# NOTE: with decay measured at only one location these are calibrated, literature
# -grounded assumptions, not a regression fitted to multi-site data. The Q10 and
# moisture half-saturation are exposed as arguments so they can be tuned or
# replaced as local data become available.

#' Climate scaling factor for dung decay
#'
#' Computes the multiplier applied to a reference decay rate to adjust it for a
#' location's climate, combining a Q10 temperature response with a saturating
#' moisture response. The factor equals 1 at the reference climate.
#'
#' @param temp_C Mean temperature of the warmest quarter at the target location
#'   (deg C; WorldClim BIO10).
#' @param precip_mm Precipitation of the warmest quarter at the target location
#'   (mm; WorldClim BIO18).
#' @param q10 Temperature sensitivity: the factor by which decay changes per
#'   10 deg C. Defaults to 2.0, a typical value for biological decomposition.
#' @param precip_half_sat Half-saturation constant for the moisture response
#'   (mm). Larger values make decay less sensitive to rainfall. Defaults to the
#'   reference site's warmest-quarter precipitation.
#' @param ref_temp_C,ref_precip_mm Reference-site climate the factor is
#'   normalised to. Defaults to the calibration values in [rancher_constants].
#'
#' @return A list with `temp_factor`, `moist_factor`, and their product
#'   `climate_factor`.
#' @examples
#' # Reference climate -> factor of 1
#' climate_decay_factor(27.31, 522)
#' # Warmer, wetter -> faster decay
#' climate_decay_factor(30, 700)
#' @export
climate_decay_factor <- function(
  temp_C,
  precip_mm,
  q10             = 2.0,
  precip_half_sat = rancher_constants$ref_precip_warmq_mm,
  ref_temp_C      = rancher_constants$ref_temp_warmq_C,
  ref_precip_mm   = rancher_constants$ref_precip_warmq_mm
) {
  temp_factor <- q10^((temp_C - ref_temp_C) / 10)

  # Saturating (Monod-type) moisture response, normalised to the reference
  m  <- precip_mm    / (precip_mm    + precip_half_sat)
  m0 <- ref_precip_mm / (ref_precip_mm + precip_half_sat)
  moist_factor <- m / m0

  list(
    temp_factor    = temp_factor,
    moist_factor   = moist_factor,
    climate_factor = temp_factor * moist_factor
  )
}

#' Look up warmest-quarter bioclim variables for a location
#'
#' Downloads (and caches) WorldClim 2.1 climate layers and extracts the mean
#' temperature of the warmest quarter (BIO10, deg C) and precipitation of the
#' warmest quarter (BIO18, mm) at a point. Requires the \pkg{terra} package and
#' an internet connection on first use; downloaded layers are cached for reuse.
#'
#' @param lat,lon Latitude and longitude in decimal degrees (WGS84).
#' @param res WorldClim spatial resolution in arc-minutes: `"10"` (default,
#'   ~18 km, smallest download), `"5"`, or `"2.5"` (~4.6 km, finer but larger).
#' @param path Directory to cache downloaded layers. Defaults to a per-user
#'   cache directory.
#' @param quiet If `TRUE`, suppress the download progress message.
#'
#' @return A named numeric vector with `temp_warmq_C` (BIO10) and
#'   `precip_warmq_mm` (BIO18).
#' @examples
#' \dontrun{
#' # Requires terra + internet (downloads ~48 MB on first call)
#' bioclim_warmest_quarter(lat = 40.0, lon = -105.3)
#' }
#' @export
bioclim_warmest_quarter <- function(
  lat,
  lon,
  res   = c("10", "5", "2.5"),
  path  = NULL,
  quiet = FALSE
) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop(
      "Package 'terra' is required to download climate data. ",
      "Install it with install.packages(\"terra\"), or pass climate values ",
      "directly via the `climate` argument of estimate_local_decay().",
      call. = FALSE
    )
  }
  res <- match.arg(res)
  if (is.null(path)) {
    path <- tryCatch(
      tools::R_user_dir("RancheR", "cache"),
      error = function(e) file.path(tempdir(), "RancheR")
    )
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)

  base_url <- "https://geodata.ucdavis.edu/climate/worldclim/2_1/base/"
  vars     <- c(temp_warmq_C = 10L, precip_warmq_mm = 18L)
  tif_path <- function(v) file.path(path, sprintf("wc2.1_%sm_bio_%d.tif", res, v))
  tifs     <- vapply(vars, tif_path, character(1))

  if (!all(file.exists(tifs))) {
    zip_file <- file.path(path, sprintf("wc2.1_%sm_bio.zip", res))
    if (!file.exists(zip_file)) {
      if (!quiet) {
        message("Downloading WorldClim 2.1 bioclim (", res, " arc-min) ...")
      }
      old_to <- options(timeout = max(600, getOption("timeout")))
      on.exit(options(old_to), add = TRUE)
      utils::download.file(
        url      = paste0(base_url, basename(zip_file)),
        destfile = zip_file,
        mode     = "wb",
        quiet    = quiet
      )
    }
    want <- sprintf("wc2.1_%sm_bio_%d.tif", res, vars)
    utils::unzip(zip_file, files = want, exdir = path, overwrite = TRUE)
  }

  pt  <- cbind(lon, lat)
  out <- vapply(vars, function(v) {
    r   <- terra::rast(tif_path(v))
    ext <- terra::extract(r, pt)        # matrix input -> no ID column
    as.numeric(ext[1, ncol(ext)])
  }, numeric(1))
  names(out) <- names(vars)

  if (anyNA(out)) {
    warning(
      "No WorldClim data at (lat=", lat, ", lon=", lon, "); ",
      "the point may be over ocean or outside the grid.",
      call. = FALSE
    )
  }
  out
}

#' Estimate local dung decay rates from a location's climate
#'
#' Estimates scenario-specific dung decay rates (g/day) at any location by
#' scaling the reference Central Florida rates by the local climate, using a Q10
#' temperature response and a saturating moisture response (see
#' [climate_decay_factor()]). Climate is taken from WorldClim warmest-quarter
#' bioclim variables, matching the summer window in which the reference rates
#' were measured.
#'
#' The same climate factor is applied to all three scenarios: it adjusts the
#' abiotic decomposition backdrop that beetle activity adds to. Supply your own
#' `climate` to avoid any download (useful offline or for testing).
#'
#' To feed the result into the economic model, pass a scaled rate as the
#' `decay_override` of [calc_dung_beetle_benefit()].
#'
#' @inheritParams bioclim_warmest_quarter
#' @param q10,precip_half_sat Passed to [climate_decay_factor()].
#' @param climate Optional named numeric vector with `temp_warmq_C` and
#'   `precip_warmq_mm` to use instead of downloading (bypasses \pkg{terra}).
#'
#' @return A list with:
#'   \describe{
#'     \item{location}{Named vector of `lat`, `lon`.}
#'     \item{climate}{Warmest-quarter temperature (deg C) and precipitation (mm) used.}
#'     \item{reference_climate}{The reference-site climate the scaling is anchored to.}
#'     \item{temp_factor, moist_factor, climate_factor}{Scaling components.}
#'     \item{decay_rates}{Named vector of estimated decay rates (g/day) for the
#'       three scenarios at this location.}
#'   }
#' @examples
#' # Offline: supply climate directly (a cooler, wetter site)
#' estimate_local_decay(
#'   lat = 44.0, lon = -89.5,
#'   climate = c(temp_warmq_C = 21, precip_warmq_mm = 300)
#' )
#' \dontrun{
#' # Online: look up climate automatically (needs terra + internet)
#' est <- estimate_local_decay(lat = 31.5, lon = -97.1)
#' calc_dung_beetle_benefit(
#'   num_cattle     = 200,
#'   scenario       = "Managed (low beetle abundance)",
#'   decay_override = est$decay_rates[["Managed (low beetle abundance)"]]
#' )
#' }
#' @export
estimate_local_decay <- function(
  lat,
  lon,
  q10             = 2.0,
  precip_half_sat = rancher_constants$ref_precip_warmq_mm,
  climate         = NULL,
  res             = c("10", "5", "2.5"),
  path            = NULL,
  quiet           = FALSE
) {
  res <- match.arg(res)

  if (is.null(climate)) {
    climate <- bioclim_warmest_quarter(lat, lon, res = res, path = path, quiet = quiet)
  } else {
    need <- c("temp_warmq_C", "precip_warmq_mm")
    if (!all(need %in% names(climate))) {
      stop(
        "`climate` must be a named vector with ",
        paste(need, collapse = " and "), ".",
        call. = FALSE
      )
    }
  }

  f <- climate_decay_factor(
    temp_C          = climate[["temp_warmq_C"]],
    precip_mm       = climate[["precip_warmq_mm"]],
    q10             = q10,
    precip_half_sat = precip_half_sat
  )

  base_rates <- c(
    "No beetles (low decay rate)"     = rancher_constants$decay_no_beetles,
    "Managed (low beetle abundance)"  = rancher_constants$decay_managed,
    "Natural (high beetle abundance)" = rancher_constants$decay_natural
  )

  list(
    location          = c(lat = lat, lon = lon),
    climate           = climate[c("temp_warmq_C", "precip_warmq_mm")],
    reference_climate = c(
      temp_warmq_C    = rancher_constants$ref_temp_warmq_C,
      precip_warmq_mm = rancher_constants$ref_precip_warmq_mm
    ),
    temp_factor    = f$temp_factor,
    moist_factor   = f$moist_factor,
    climate_factor = f$climate_factor,
    decay_rates    = base_rates * f$climate_factor
  )
}
