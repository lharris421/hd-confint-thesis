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

res_list <- readRDS(glue("{opt$loc}rds/{iterations}/across_lambda_coverage.rds"))
model_cov <- readRDS(glue("{opt$loc}rds/{iterations}/across_lambda_gam.rds"))

lambdas <- res_list$lambdas
res <- res_list$res
lambda_maxs <- res %>% group_by(group) %>% filter(row_number() == 1) %>% pull(lambda_max)

pdat <- res %>%
  dplyr::mutate(covered = truth >= lower & truth <= upper,
                group = as.factor(group),
                lambda = round(lambda / lambda_max, 3),
                truth = abs(truth))


lambda_cov <- pdat %>%
  group_by(group, lambda) %>%
  summarise(off_coverage = abs(mean(covered) - .8)) %>%
  arrange(off_coverage) %>%
  summarise(lambda = first(lambda)) %>%
  pull(lambda) %>%
  median()

# Create a grid for prediction on the transformed lambda scale
min_lam <- min(c(lambdas, lambda_cov))
lambda_seq <- 10^seq(log(.05, 10), log(1, 10), length.out = 100)
truth_seq <- seq(0, 3, length.out = 100)
grid <- expand.grid(lambda = lambda_seq, truth = truth_seq) %>% data.frame()

# Predict coverage probability
grid$coverage <- predict(model_cov, newdata = grid, type ="response")
grid$adjusted_coverage <- grid$coverage - 0.8


my_breaks <- c(1, 0.5, 0.2, 0.1, 0.05)
my_labels <- function(x) {
  parse(text = sapply(x, function(val) {
    frac_val <- paste0(" / ", 1/val)
    if (frac_val == " / 1") frac_val <- "    "
    paste("lambda[max]", frac_val)
  }))
}

# Plot the heatmap with reversed lambda on the log10 scale
plt_cov <- ggplot(grid, aes(x = lambda, y = truth, fill = adjusted_coverage)) +
  geom_tile() +
  scale_fill_gradient2(low = "#DF536B", high = "#2297E6", mid = "white", midpoint = 0, labels   = percent_format(accuracy = 1)) +
  labs(y = expression(abs(beta)), fill = "Rel. Cov.", x = expression(lambda)) +
  scale_x_log10(trans   = c("log10", "reverse"), breaks  = my_breaks, labels  = my_labels) +
  geom_vline(xintercept = median(lambdas), alpha = .5, col = "black", linetype = "dashed") +
  geom_vline(xintercept = lambda_cov, alpha = .5, col = "blue") +
  geom_vline(xintercept = c(quantile(lambdas, 0.125), quantile(lambdas, 0.875))) +
  theme_minimal()


if (interactive()) {
  png("out/figure3.png", height = 3.1, width = 3.9, units='in', res = 300)
} else {
  png("code/out/figure3.png", height = 3.1, width = 3.9, units='in', res = 300)
}
plt_cov
dev.off()

