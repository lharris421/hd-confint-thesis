if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=1000),
  make_option(c("-d", "--desparsified"), action="store_true", default=FALSE),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations
desparsified <- opt$desparsified

methods <- c("rlp", "pipep", "lqap")


results_lookup <- expand.grid(
  method = methods,
  n = c(50, 100, 400)
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/gam/laplace_autoregressive_0_{results_lookup[i,'n']}_101_gaussian_100_{results_lookup[i,'method']}.rds"))
}
line_data <- bind_rows(results) %>%
  mutate(
    method = factor(method_labels[method], levels = c("RL Posterior", "PIPE Posterior", "LQA Posterior"))
    # n = factor(n, levels = c(50, 100, 400))
  )

cutoff <- max(line_data$x)
xvals <- seq(from = -cutoff, to = cutoff, length.out = cutoff * 100 + 1)
density_data <- data.frame(x = xvals, density = 2 * dlaplace(xvals, rate = 1.414))

p1 <- ggplot(data = line_data) +
  geom_line(aes(x = x, y = y, color = method)) +
  geom_hline(aes(yintercept = average_coverage, color = method), linetype = 2) +
  geom_hline(aes(yintercept = 0.8), linetype = 1, alpha = .5) +
  geom_area(data = density_data, aes(x = x, y = density / max(density)), fill = "grey", alpha = 0.5) +
  theme_minimal() +
  xlab(expression(beta)) +
  ylab("Coverage") +
  coord_cartesian(ylim = c(0, 1)) +
  scale_color_manual(name = "Method", values = colors) +
  facet_wrap(~n, labeller = label_bquote(n == .(n))) +
  scale_y_continuous(labels = scales::label_percent())

if (interactive()) {
  pdf("out/figure1-man2.pdf", width = 5.2, height = 3)
} else {
  pdf("code/out/figure1-man2.pdf", width = 5.2, height = 3)
}
p1
dev.off()
