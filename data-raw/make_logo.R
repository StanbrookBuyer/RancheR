# Generates the RancheR hex sticker -> man/figures/logo.png
# Uses the dung-beetle silhouette (data-raw/beetle.png): white background made
# transparent, tinted dark, centred on the olive hex. Pure ggplot2 + png.
# Run from the package root:  Rscript data-raw/make_logo.R
library(ggplot2)

## ---- palette (RancheR app brand) -------------------------------------------
olive      <- "#6B8E23"
olive_dark <- "#3d5016"
cream      <- "#FDFAF6"
beetle     <- "#241712"   # dark beetle tint

## ---- geometry helpers ------------------------------------------------------
# Canonical R hex sticker outline (point top & bottom, flat sides)
hexd <- data.frame(
  x = c(-sqrt(3) / 2, -sqrt(3) / 2, 0, sqrt(3) / 2, sqrt(3) / 2, 0),
  y = c(0.5, -0.5, -1, -0.5, 0.5, 1)
)
hex_scaled <- function(s) data.frame(x = hexd$x * s, y = hexd$y * s)
poly <- function(p, fill, colour = NA, linewidth = 0) {
  geom_polygon(data = p, aes(x, y), fill = fill, colour = colour, linewidth = linewidth)
}

## ---- beetle silhouette -> tinted, transparent raster -----------------------
src   <- png::readPNG("data-raw/beetle.png")
gray  <- (src[, , 1] + src[, , 2] + src[, , 3]) / 3
alpha <- 1 - gray                 # white -> 0 (transparent), black -> 1 (opaque)
alpha[alpha < 0.15] <- 0          # drop faint JPEG halo around the silhouette

rgb_b <- grDevices::col2rgb(beetle) / 255
rgba  <- array(0, dim = c(nrow(gray), ncol(gray), 4))
rgba[, , 1] <- rgb_b[1]; rgba[, , 2] <- rgb_b[2]; rgba[, , 3] <- rgb_b[3]
rgba[, , 4] <- alpha
beetle_raster <- grDevices::as.raster(rgba)

# centre the beetle in the upper hex, preserving aspect ratio
asp  <- ncol(gray) / nrow(gray)   # width / height
bh   <- 0.84                      # beetle height in hex units
bw   <- bh * asp
bcx  <- 0; bcy <- 0.30

## ---- build the plot --------------------------------------------------------
p <- ggplot() +
  # hex body + border + thin inner stroke
  poly(hexd, fill = olive, colour = olive_dark, linewidth = 5) +
  poly(hex_scaled(0.90), fill = NA, colour = cream, linewidth = 0.9) +

  # beetle silhouette
  annotation_raster(beetle_raster,
                    xmin = bcx - bw / 2, xmax = bcx + bw / 2,
                    ymin = bcy - bh / 2, ymax = bcy + bh / 2,
                    interpolate = TRUE) +

  # wordmark
  annotate("text", x = 0, y = -0.34, label = "RancheR",
           family = "sans", fontface = "bold", colour = cream, size = 9) +

  coord_fixed(xlim = c(-1, 1), ylim = c(-1.15, 1.15), expand = FALSE, clip = "off") +
  theme_void() +
  theme(
    plot.background  = element_rect(fill = "transparent", colour = NA),
    panel.background = element_rect(fill = "transparent", colour = NA)
  )

ggsave("man/figures/logo.png", p, width = 2.4, height = 2.4 * 2.3 / 2,
       dpi = 600, bg = "transparent")
cat("wrote man/figures/logo.png\n")
