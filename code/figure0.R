if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

beta_seq <- seq(-4, 4, by = .01)
lambda   <- 0.5
sigma2   <- 1
n        <- 1
zjs      <- c(0.1, 0.3, 0.6, 1)

# Lasso (piecewise normal) component kernels, unnormalized (your form)
neg_full <- function(x, n, lambda, zj, sigma2) {
  exp((zj*lambda*n)/sigma2) * exp(-(n/(2*sigma2))*(x - (zj + lambda))^2)
}
pos_full <- function(x, n, lambda, zj, sigma2) {
  exp(-(zj*lambda*n)/sigma2) * exp(-(n/(2*sigma2))*(x - (zj - lambda))^2)
}

res <- lapply(zjs, function(zj) {
  x <- beta_seq
  y_neg_full <- neg_full(x, n, lambda, zj, sigma2)
  y_pos_full <- pos_full(x, n, lambda, zj, sigma2)

  # dotted reference curves (full normals on both sides)
  df_ref <- rbind(
    data.frame(x = x, y = y_neg_full, component = "Negative", layer = "ref"),
    data.frame(x = x, y = y_pos_full, component = "Positive", layer = "ref")
  )

  # solid "used" halves (posterior chooses side by sign of x)
  df_used <- rbind(
    data.frame(x = x, y = ifelse(x <= 0, y_neg_full, NA_real_), component = "Negative", layer = "used"),
    data.frame(x = x, y = ifelse(x >  0, y_pos_full, NA_real_), component = "Positive", layer = "used")
  )

  dplyr::bind_rows(df_ref, df_used) |>
    dplyr::mutate(zj = zj)
})

df_all <- dplyr::bind_rows(res)

# Write the figure
if (interactive()) {
  pdf("out/figure0.pdf", width = 4.5, height = 4.5)
} else {
  pdf("code/out/figure0.pdf", width = 4.5, height = 4.5)
}

ggplot2::ggplot() +
  # dotted, faded full normals first (unused portions visible)
  ggplot2::geom_line(
    data = subset(df_all, layer == "ref"),
    ggplot2::aes(x = x, y = y, color = component),
    linetype = "dotted", alpha = 0.7, linewidth = 0.9, na.rm = TRUE
  ) +
  # solid "used" halves on top (posterior)
  ggplot2::geom_line(
    data = subset(df_all, layer == "used"),
    ggplot2::aes(x = x, y = y, color = component),
    linewidth = 1.2, na.rm = TRUE
  ) +
  ggplot2::scale_color_manual(values = c(
    "Negative" = "red",
    "Positive" = "blue"
  )) +
  ggplot2::facet_wrap(~zj, labeller = label_bquote(mu == .(zj)), nrow = 2) +
  ggplot2::guides(color = "none") +
  ggplot2::theme_minimal() +
  ggplot2::theme(panel.spacing = grid::unit(1, "lines")) +
  ggplot2::xlab(expression(beta)) +
  ggplot2::ylab("Density") +
  coord_cartesian(ylim = c(0, 1.1))

dev.off()
