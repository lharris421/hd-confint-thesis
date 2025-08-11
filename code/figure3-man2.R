if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=100),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations

results_lookup <- expand.grid(
  n = c(50, 100, 400, 1000),
  rho = c(0, 50, 80),
  method = c("rlp", "pipep", "lqap")
)


results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/original/laplace_autoregressive_{results_lookup[i,'rho']}_{results_lookup[i,'n']}_101_gaussian_100_{results_lookup[i,'method']}.rds"))
}
res <- bind_rows(results) %>%
  mutate(method = method_labels[method])

# Transform and summarize data
width_data <- res %>%
  mutate(width = upper - lower, n = as.factor(n), rho = factor(rho / 100)) %>%
  group_by(method, rho, n) %>%
  summarise(lower = quantile(width, 0.25), upper = quantile(width, 0.75), width = median(width), .groups = 'drop')

# Create a single plot with facets for each rho
final_plot <- width_data %>%
  ggplot(aes(x = rho, y = width, color = n, group = n)) +
  facet_wrap(~method, labeller = label_bquote(.(method))) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.1) +
  labs(x = expression(rho), y = "Width") +
  theme_minimal()

# Print the plot
if (interactive()) {
  pdf("out/figure3-man2.pdf", width = 5.2, height = 3)
} else {
  pdf("code/out/figure3-man2.pdf", width = 5.2, height = 3)
}
final_plot
dev.off()
