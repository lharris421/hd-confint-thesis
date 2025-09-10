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
coverage_data <- res %>%
  mutate(rho = rho / 100) %>%
  mutate(
    covered = lower <= truth & upper >= truth,
    n = as.factor(n),
    rho = factor(rho)
  ) %>%
  group_by(iteration, method, rho, n) %>%
  summarise(coverage = mean(covered, na.rm = TRUE), .groups = 'drop')


# Create a single plot with facets for each rho
final_plot <- coverage_data %>%
  ggplot(aes(x = rho, y = coverage, fill = rho)) +
  geom_violin(adjust = 1.5) +
  facet_wrap(method~n, as.table = FALSE, labeller = label_bquote(.(method) - n == .(unique(results_lookup$n)[n]))) +
  labs(x = expression(rho), y = "Coverage Rate") +
  theme_minimal() +
  theme(legend.position = "none") +
  geom_hline(yintercept = 0.8) +
  coord_cartesian(ylim = c(0, 1))

# Print the plot
if (interactive()) {
  pdf("out/figure2-man2.pdf", width = 6.5, height = 4.5)
} else {
  pdf("code/out/figure2-man2.pdf", width = 6.5, height = 4.5)
}
final_plot
dev.off()
