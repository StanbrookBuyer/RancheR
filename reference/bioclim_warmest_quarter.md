# Look up warmest-quarter bioclim variables for a location

Downloads (and caches) WorldClim 2.1 climate layers and extracts the
mean temperature of the warmest quarter (BIO10, deg C) and precipitation
of the warmest quarter (BIO18, mm) at a point. Requires the terra
package and an internet connection on first use; downloaded layers are
cached for reuse.

## Usage

``` r
bioclim_warmest_quarter(
  lat,
  lon,
  res = c("10", "5", "2.5"),
  path = NULL,
  quiet = FALSE
)
```

## Arguments

- lat, lon:

  Latitude and longitude in decimal degrees (WGS84).

- res:

  WorldClim spatial resolution in arc-minutes: `"10"` (default, ~18 km,
  smallest download), `"5"`, or `"2.5"` (~4.6 km, finer but larger).

- path:

  Directory to cache downloaded layers. Defaults to a per-user cache
  directory.

- quiet:

  If `TRUE`, suppress the download progress message.

## Value

A named numeric vector with `temp_warmq_C` (BIO10) and `precip_warmq_mm`
(BIO18).

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires terra + internet (downloads ~48 MB on first call)
bioclim_warmest_quarter(lat = 40.0, lon = -105.3)
} # }
```
