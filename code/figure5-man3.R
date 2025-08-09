if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}


option_list <- list(
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))

methods <- c("pipep", "pipepscad", "pipepmcp")

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

cis <- bind_rows(results)
cis %>% pull(lambda) %>% unique()

gg <- cis %>%
  arrange(method, estimate) %>%
  mutate(
    variable = factor(variable, levels = unique(variable)),
    method = factor(method, levels = unique(method), labels = unique(method))
  ) %>%
  ggplot(aes(y = variable)) +
  geom_point(aes(x = estimate)) +
  geom_errorbar(aes(xmin = lower, xmax = upper)) +
  facet_wrap(~ method) +
  theme_minimal() +
  coord_cartesian(xlim = c(-0.5, 0.5))

if (interactive()) {
  pdf("out/figure5-man3.pdf", height = 3.9, width = 5.9)
} else {
  pdf("code/out/figure5-man3.pdf", height = 3.9, width = 5.9)
}
gg
dev.off()
