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
  mutate(method = method_labels[method],
         estimate = coef)

if (interactive()) {
  pdf("out/figure5-man2.pdf", height = 3.9, width = 5.9)
} else {
  pdf("code/out/figure5-man2.pdf", height = 3.9, width = 5.9)
}
plot_ci_comparison(results, nvars = 30, ref = "Relaxed Lasso Posterior")
dev.off()
