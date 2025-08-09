if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}


option_list <- list(
  make_option(c("--loc"), type="character", default="")
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
  mutate(method = method_labels[method])

sig_vars <- results %>%
  mutate(is_not_zero = lower > 0 | upper < 0) %>%
  filter(is_not_zero) %>%
  ggplot(aes(x = coef, y = method)) +
  geom_label(aes(label = variable), position = position_dodge2(width = .8), size = 1.8) +
  theme_minimal() +
  ylab("") + xlab("LASSO Estimate")


if (interactive()) {
  pdf("out/figure6-man2.pdf", height = 3.9, width = 6.5)
} else {
  pdf("code/out/figure6-man2.pdf", height = 3.9, width = 6.5)
}
sig_vars
dev.off()
