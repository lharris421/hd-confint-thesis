if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

## --- Parameters ---
mu     <- c(0.1, 0.3, 0.6, 1)
# mu <- 0.3
s2     <- 1
lambda <- .5
gamma  <- 3
penalty <- "MCP"

if (interactive()) {
  pdf("out/figure2-man3.pdf", width = 4.5, height = 4.5)
} else {
  pdf("code/out/figure2-man3.pdf", width = 4.5, height = 4.5)
}
plot_piecewise_components(mu, s2, lambda, gamma) +
  coord_cartesian(ylim = c(0, 1.1), xlim = c(-4, 4))
dev.off()
