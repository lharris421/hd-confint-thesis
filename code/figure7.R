if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}


option_list <- list(
  make_option(c("-d", "--desparsified"), action="store_true", default=FALSE),
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))
desparsified <- opt$desparsified

methods <- c("rlp", "selectiveinference")
if (desparsified) methods <- c(methods, "desparsified")

results_lookup <- expand.grid(
  method = methods
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/Scheetz2006_{results_lookup[i,'method']}.rds"))
}

results <- bind_rows(results) %>%
  mutate(method = method_labels[method],
         estimate = ifelse(method == "RL Posterior", coef, estimate))

if (interactive()) {
  pdf("out/figure7.pdf", height = 3.9, width = 5.9)
} else {
  pdf("code/out/figure7.pdf", height = 3.9, width = 5.9)
}
plot_ci_comparison(results, nvars = 30, ref = "RL Posterior")
dev.off()
