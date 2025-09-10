if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=1000),
  make_option(c("-d", "--desparsified"), action="store_true", default=FALSE),
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations
desparsified <- opt$desparsified

methods <- c("lqapbinom", "lqappois")

results_lookup <- expand.grid(
  n      = c(50, 100, 400, 1000),
  family = c("binomial", "poisson")
) %>%
  mutate(method = ifelse(family == "binomial", methods[1], methods[2]))

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/gam/laplace_autoregressive_0_{results_lookup[i,'n']}_101_{results_lookup[i,'family']}_100_{results_lookup[i,'method']}.rds"))
}
line_data <- bind_rows(results) %>%
  mutate(
    method = method_labels[method],
    n      = factor(n, levels = c(50, 100, 400, 1000)),
    family = ifelse(family == "binomial", "logistic", family),
    family = factor(stringr::str_to_title(family), levels = c("Logistic", "Poisson"))
  )

cutoff <- max(line_data$x)
xvals <- seq(from = -cutoff, to = cutoff, length.out = cutoff * 100 + 1)
density_data <- data.frame(x = xvals, density = 2 * dlaplace(xvals, rate = 1.414))

p1 <- ggplot(data = line_data) +
  geom_line(aes(x = x, y = y, color = n)) +
  geom_hline(aes(yintercept = average_coverage, color = n), linetype = 2) +
  geom_hline(aes(yintercept = 0.8), linetype = 1, alpha = .5) +
  theme_minimal() +
  xlab(expression(beta)) +
  ylab("Estimated Coverage") +
  coord_cartesian(ylim = c(0, 1)) +
  facet_wrap(vars(family), scales = "free_x")

if (interactive()) {
  pdf("out/figureA1-man3.pdf", width = 5.2, height = 2.5)
} else {
  pdf("code/out/figureA1-man3.pdf", width = 5.2, height = 2.5)
}
p1
dev.off()
