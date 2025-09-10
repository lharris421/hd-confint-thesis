if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}


option_list <- list(
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))

methods <- c("rlp", "pipep", "lqap")

results_lookup <- expand.grid(
  method = methods
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/Scheetz2006_{results_lookup[i,'method']}.rds"))
}

results <- bind_rows(results) %>%
  mutate(method = method_labels[method],
         estimate = coef)

sig_vars <- results %>%
  mutate(is_not_zero = lower > 0 | upper < 0) %>%
  filter(is_not_zero) %>%
  ggplot(aes(x = coef, y = method)) +
  geom_label(aes(label = variable), position = position_dodge2(width = .8), size = 2.5) +
  theme_minimal() +
  ylab("") + xlab("LASSO Estimate")

if (interactive()) {
  pdf("out/figure5-man2.pdf", height = 3.9, width = 5.9)
} else {
  pdf("code/out/figure5-man2.pdf", height = 3.9, width = 5.9)
}
plot_vars <- results %>%
  mutate(is_not_zero = lower > 0 | upper < 0) %>%
  filter(is_not_zero) %>%
  arrange(coef) %>%
  pull(variable) %>%
  unique()

plot_res <- results %>%
  mutate(is_not_zero = lower > 0 | upper < 0) %>%
  filter(variable %in% plot_vars) %>%
  dplyr::arrange(desc(estimate))

plot_res$variable <- factor(plot_res$variable, levels = rev(plot_vars))
plot_res$method <- factor(plot_res$method, levels = unique(results$method))

plot_res %>%
  group_by(variable) %>%
  arrange(method) %>%
  mutate(
    estimate = ifelse(is.na(estimate), NA, first(estimate)),
    lowerF    = ifelse(is.infinite(lower), NA, lower),
    upperF    = ifelse(is.infinite(upper), NA, upper)
  ) %>%
  ungroup() %>%
  ggplot() +
  geom_errorbar(aes(xmin = lower, xmax = upper, y = variable, color = is_not_zero), width = 0) +
  geom_point(aes(x = estimate, y = variable), shape = 1, size = 1) +
  theme_minimal() +
  ylab("Gene") + xlab("Estimate (80% CI)") +
  scale_color_manual(values = c("black", "red")) +
  theme(legend.position = "none",
        legend.justification = c("right", "bottom"),
        legend.box.just = "right",
        legend.margin = margin(6, 6, 6, 6),
        legend.background = element_rect(fill = "transparent"),
        axis.text.y = element_blank()
  ) +
  facet_wrap(~method, nrow = 1)
dev.off()
