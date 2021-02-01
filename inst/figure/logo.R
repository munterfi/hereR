library(hereR)
library(hexSticker)
library(ggplot2)
library(sf)

outfile <- paste0(here::here(), "/man/figures/logo.svg")

# Colors
grey <- "#393e47"
green <- "#65c1c2"
white <- "#FFFFFF"

# Isolines
iso <- isoline(poi[poi$city %in% c("Zürich"), ], range = seq(1, 15, 0.5) * 60)
p <- ggplot(iso) +
  geom_sf(aes(fill = range), lwd = 0, color = NA) +
  theme_void() +
  theme(panel.background = element_rect(fill = NA)) +
  scale_fill_gradient(low = green, high = grey) +
  guides(shape = FALSE, fill = FALSE, color = FALSE)

# Sticker
sticker(p,
  package = "", p_size = 12,
  s_x = 1, s_y = 1, s_width = 1.9, s_height = 1.9,
  h_fill = grey, h_color = green,
  filename = outfile, white_around_sticker = FALSE,
  url = "hereR", u_color = white, u_x = 0.95, u_y = 0.2, u_size = 8, u_angle = 30
)
