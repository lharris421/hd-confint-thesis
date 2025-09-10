if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=1000),
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations

results_lookup <- expand.grid(
  n = c(50, 100, 400)
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/gam/laplace_autoregressive_0_{results_lookup[i,'n']}_101_gaussian_100_rlp.rds"))
}
line_data <- bind_rows(results) %>%
  mutate(
    method = method_labels[method],
    n = factor(n, levels = c(50, 100, 400))
  )

cutoff <- max(line_data$x)
xvals <- seq(from = -cutoff, to = cutoff, length.out = cutoff * 100 + 1)
density_data <- data.frame(x = xvals, density = 2 * dlaplace(xvals, rate = 1.414))

p1 <- ggplot() +
  geom_line(data = line_data, aes(x = x, y = y, color = n)) +
  geom_hline(data = line_data, aes(yintercept = average_coverage, color = n), linetype = 2) +
  geom_hline(aes(yintercept = 0.8), linetype = 1, alpha = .5) +
  geom_area(data = density_data, aes(x = x, y = density / max(density)), fill = "grey", alpha = 0.5) +
  theme_minimal() +
  xlab(expression(beta)) +
  ylab("Estimated Coverage") +
  coord_cartesian(ylim = c(0, 1)) +
  scale_color_manual(name = "Sample Size", values = colors)

if (interactive()) {
  pdf("out/figureC1.pdf", height = 2.9, width = 3.9)
} else {
  pdf("code/out/figureC1.pdf", height = 2.9, width = 3.9)
}
p1
dev.off()
