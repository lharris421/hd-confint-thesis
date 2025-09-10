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

results <- readRDS(glue("{opt$loc}rds/{iterations}/gam/laplace_autoregressive_0_100_101_gaussian_100_traditional.rds"))

line_data <- results %>%
  mutate(method = method_labels[method])

cutoff <- max(line_data$x)
xvals <- seq(from = -cutoff, to = cutoff, length.out = cutoff * 100 + 1)
density_data <- data.frame(x = xvals, density = 2 * dlaplace(xvals, rate = 1.414))

p1 <- ggplot() +
  geom_line(data = line_data, aes(x = x, y = y, color = method)) +
  geom_hline(data = line_data, aes(yintercept = average_coverage, color = method), linetype = 2) +
  geom_hline(aes(yintercept = 0.8), linetype = 1, alpha = .5) +
  geom_area(data = density_data, aes(x = x, y = density / max(density)), fill = "grey", alpha = 0.5) +
  theme_minimal() +
  xlab(expression(beta)) +
  ylab("Estimated Coverage") +
  coord_cartesian(ylim = c(0, 1)) +
  scale_color_manual(name = "Method", values = colors) +
  theme(legend.position = "none")

if (interactive()) {
  pdf("out/figureA1.pdf", height = 3.3, width = 4.6)
} else {
  pdf("code/out/figureA1.pdf", height = 3.3, width = 4.6)
}
p1
dev.off()
