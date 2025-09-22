if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}


option_list <- list(
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))

methods <- c("lqap", "lqapscad", "lqapmcp")

results_lookup <- expand.grid(
  method = methods
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/whoari_{results_lookup[i,'method']}.rds"))

  results[[i]] <- results[[i]] %>%
    select(!estimate) %>%
    rename(estimate = coef)
}

results <- bind_rows(results) %>%
  mutate(method = method_labels[method])

vars_keep <- results %>%
  filter(estimate != 0) %>%
  pull(variable) %>%
  unique()

var_order <- results %>%
  filter(variable %in% vars_keep, method == "LQA Posterior") %>%
  arrange(abs(estimate)) %>%
  pull(variable)

cis <- results %>%
  filter(variable %in% vars_keep)

dodge <- position_dodgev(height = 0.6)  # vertical dodge so methods sit side-by-side per variable

gg <- cis %>%
  # arrange(variable, method) %>%
  mutate(
    variable = factor(variable, levels = var_order),  # optional: control order
    method   = factor(method, levels = unique(method))
  ) %>%
  ggplot(aes(y = variable, color = method)) +
  # horizontal CI bars, dodged vertically by method
  geom_errorbarh(aes(xmin = lower, xmax = upper),
                 position = dodge, height = 0) +
  # point at the estimate, also dodged vertically
  geom_point(aes(x = estimate, shape = method),
             position = dodge, size = 1.8, stroke = 0.6) +
  # reference line at 0
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  theme_minimal() +
  coord_cartesian(xlim = c(-0.5, 0.5)) +
  labs(x = "Estimate (80% CI)", y = "Variable", color = "Method", shape = "Method") +
  theme(legend.position = "bottom")

if (interactive()) {
  pdf("out/figureA2-man3.pdf", height = 7, width = 6.5)
} else {
  pdf("code/out/figureA2-man3.pdf", height = 7, width = 6.5)
}
gg
dev.off()
