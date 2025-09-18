if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}


option_list <- list(
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))

methods <- c("lqapbinom", "lqapbinommcp", "lqapbinomsnet")

results_lookup <- expand.grid(
  method = methods
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/Golub1999_{results_lookup[i,'method']}.rds")) %>%
    group_by(variable) %>%
    mutate(variable = make.unique(as.character(variable), sep = ""))
}

results <- bind_rows(results) %>%
  mutate(method = method_labels[method])

if (interactive()) {
  pdf("out/figureB1-man3.pdf", height = 4.5, width = 6.5)
} else {
  pdf("code/out/figureB1-man3.pdf", height = 4.5, width = 6.5)
}
plot_vars <- results %>%
  # mutate(is_not_zero = lower > 0 | upper < 0) %>%
  mutate(is_not_zero = coef != 0) %>%
  filter(is_not_zero) %>%
  pull(variable) %>%
  unique()

plot_res <- results %>%
  mutate(is_not_zero = lower > 0 | upper < 0) %>%
  filter(variable %in% plot_vars)

plot_res$variable <- factor(plot_res$variable, levels = rev(plot_vars))
plot_res$method <- factor(plot_res$method, levels = unique(results$method))

plot_res %>%
  ggplot() +
  geom_errorbar(aes(xmin = lower, xmax = upper, y = variable, color = is_not_zero), height = 0.5) +
  geom_point(aes(x = coef, y = variable), shape = 1, size = 1) +
  theme_minimal() +
  ylab("Gene") + xlab("Estimate (80% CI)") +
  scale_color_manual(values = c("black", "red")) +
  theme(legend.position = "none",
        legend.justification = c("right", "bottom"),
        legend.box.just = "right",
        legend.margin = margin(6, 6, 6, 6),
        legend.background = element_rect(fill = "transparent")
  ) +
  facet_wrap(~method, nrow = 1)
dev.off()
