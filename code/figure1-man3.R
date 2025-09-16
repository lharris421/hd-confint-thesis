if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

mn <- 1
lambda <- 0.5
sd <- 1
x_range <- seq(-5, 5, by = 0.01)
alpha <- 0.05

left_norm <- dnorm(x_range, mean = mn + lambda, sd = sd)
right_norm <- dnorm(x_range, mean = mn - lambda, sd = sd)

multiplier <- right_norm[x_range == 0] / left_norm[x_range == 0]
posterior <- c(left_norm[x_range <= 0]* multiplier, right_norm[x_range > 0])
posterior <- posterior / sum(posterior * 0.01)

## dif
# max(abs(dens - posterior))

## Numerically
cdf <- cumsum(posterior * 0.01)
lower_num <- x_range[which.min(abs(cdf - alpha/2))]
upper_num <- x_range[which.min(abs(cdf - (1 - alpha/2)))]

## Computational Shortcut
ci_comp <- ncvreg:::laplace_ci(mn, lambda, sd, alpha = alpha)
lower_comp <- ci_comp$lower
upper_comp <- ci_comp$upper

## Static
# Create a data frame with the x values and corresponding densities.
df <- data.frame(
  x = x_range,
  posterior = posterior,
  left_norm = left_norm,
  right_norm = right_norm
)

# Define subsets for shading:
# For the posterior, shade the tails outside the CI bounds.
df_post_left  <- subset(df, x < lower_comp)
df_post_right <- subset(df, x > upper_comp)

# For the normals, shade only the "solid" portions.
# For left_norm (solid for x <= 0), shade the region x < lower_comp (if lower_comp is in the left side).
df_left_shade <- subset(df, x <= 0 & x < lower_comp)
# For right_norm (solid for x > 0), shade the region x > upper_comp.
df_right_shade <- subset(df, x > 0 & x > upper_comp)

# Build the ggplot
gg <- ggplot() +
  # Shading for posterior tails in gray.
  geom_ribbon(data = df_post_left, aes(x = x, ymin = 0, ymax = posterior), fill = "gray", alpha = 0.3) +
  geom_ribbon(data = df_post_right, aes(x = x, ymin = 0, ymax = posterior), fill = "gray", alpha = 0.3) +
  # Shading for the solid region of left_norm in blue.
  geom_ribbon(data = df_left_shade, aes(x = x, ymin = 0, ymax = left_norm), fill = "blue", alpha = 0.3) +
  # Shading for the solid region of right_norm in red.
  geom_ribbon(data = df_right_shade, aes(x = x, ymin = 0, ymax = right_norm), fill = "red", alpha = 0.3) +
  # Add the posterior density curve (black)
  geom_line(data = df, aes(x = x, y = posterior), color = "black", linewidth = 1) +
  # Plot full left_norm: solid for x <= 0, dashed for x > 0.
  geom_line(data = subset(df, x <= 0), aes(x = x, y = left_norm), color = "blue", linewidth = 1) +
  geom_line(data = subset(df, x > 0), aes(x = x, y = left_norm), color = "blue", linewidth = 1, linetype = "dotted") +
  # Plot full right_norm: dashed for x <= 0, solid for x > 0.
  geom_line(data = subset(df, x <= 0), aes(x = x, y = right_norm), color = "red", linewidth = 1, linetype = "dotted") +
  geom_line(data = subset(df, x > 0), aes(x = x, y = right_norm), color = "red", linewidth = 1) +
  # Add vertical lines for the CI bounds.
  geom_vline(xintercept = lower_comp, color = "black", linetype = "dashed") +
  geom_vline(xintercept = upper_comp, color = "black", linetype = "dashed") +
  geom_vline(xintercept = 0, color = "black") +
  theme_minimal() +
  labs(
    x = "x",
    y = "Density",
  ) +
  coord_cartesian(xlim = c(-2, 4))

# Print the plot
if (interactive()) {
  pdf("out/figure1-man3.pdf", width = 3.9, height = 2)
} else {
  pdf("code/out/figure1-man3.pdf", width = 3.9, height = 2)
}
gg
dev.off()
