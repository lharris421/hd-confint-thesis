if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("-d", "--desparsified"), action="store_true", default=FALSE),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
print(opt)
desparsified <- opt$desparsified

methods <- c("rlp", "selectiveinference")
if (desparsified) methods <- c(methods, "desparsified")

results_lookup <- expand.grid(
  method = methods
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/whoari_{results_lookup[i,'method']}.rds"))
}


results <- bind_rows(results) %>%
  mutate(method = method_labels[method],
         estimate = ifelse(method == "Relaxed Lasso Posterior", coef, estimate))

if (interactive()) {
  pdf("out/figure6.pdf", height = 6.2, width = 5.9)
} else {
  pdf("code/out/figure6.pdf", height = 6.2, width = 5.9)
}
plot_ci_comparison(results, nvars = 66, ref = "Relaxed Lasso Posterior")
dev.off()
