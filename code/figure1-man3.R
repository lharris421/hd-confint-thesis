if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

beta_seq <- seq(-4, 4, by = .01)
lambda <- 0.4
sigma2 <- 1
n <- 1
zjs <- c(0.1, 0.5, 1)

post_dens <- function(x, n, lambda, zj, sigma2) {
  if (x < 0) {
    exp((zj*lambda*n)/sigma2)*exp(-(n / (2*sigma2))*(x - (zj + lambda))^2)
  } else {
    exp(-(zj*lambda*n)/sigma2)*exp(-(n / (2*sigma2))*(x - (zj - lambda))^2)
  }
}

res <- list()
for (i in 1:length(zjs)) {
  dens <- sapply(beta_seq, post_dens, n, lambda, zjs[i], sigma2)
  # dens <- dens / max(dens)
  res[[i]] <- data.frame(x = beta_seq, y = dens, zj = zjs[i])
}

if (interactive()) {
  pdf("out/figure1-man3.pdf", width = 5.2, height = 3)
} else {
  pdf("code/out/figure1-man3.pdf", width = 5.2, height = 3)
}
do.call(dplyr::bind_rows, res) %>%
  ggplot2::ggplot(aes(x = x, y = y)) +
  ggplot2::geom_area(alpha = 0.5) +
  ggplot2::facet_wrap(~zj, labeller = label_bquote(mu == .(zj))) +
  theme_bw() +
  theme(panel.spacing = unit(1, "lines")) +
  xlab(expression(beta)) +
  ylab("Density")
dev.off()
