# RancheR in a container -------------------------------------------------------
#
# Build:
#   docker build -t rancher .
#
# Run an interactive R session with RancheR preloaded:
#   docker run --rm -it rancher
#
# Run a one-off calculation:
#   docker run --rm rancher Rscript -e \
#     'RancheR::calc_dung_beetle_benefit(100, "Managed (low beetle abundance)")$annual_value'
#
# Persist the (~48 MB) WorldClim download between runs by mounting a cache:
#   docker run --rm -it -v rancher_cache:/data/cache rancher
# -------------------------------------------------------------------------------

# Pinned, versioned R image from the Rocker project (change the tag to match
# your R version if needed).
FROM rocker/r-ver:4.6.0

# System libraries required by 'terra' (GDAL / GEOS / PROJ) so the climate
# functions (estimate_local_decay, bioclim_warmest_quarter) work.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libgdal-dev \
      libgeos-dev \
      libproj-dev \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# RancheR's core functions have no dependencies; 'terra' powers the optional
# WorldClim climate lookup.
RUN install2.r --error --skipinstalled terra

# Install RancheR from the local source tree.
WORKDIR /opt/RancheR
COPY . /opt/RancheR
RUN R CMD build --no-build-vignettes . \
    && R CMD INSTALL RancheR_*.tar.gz \
    && rm -f RancheR_*.tar.gz

# Cache WorldClim downloads here; mount a volume to reuse across runs.
# tools::R_user_dir("RancheR", "cache") honours this environment variable.
ENV R_USER_CACHE_DIR=/data/cache
RUN mkdir -p /data/cache

WORKDIR /work

# Attach RancheR automatically in interactive sessions (does not affect Rscript).
RUN echo 'if (interactive()) suppressMessages(library(RancheR))' \
      >> "$(R RHOME)/etc/Rprofile.site"

# Default: an interactive R prompt with RancheR already loaded.
CMD ["R"]
