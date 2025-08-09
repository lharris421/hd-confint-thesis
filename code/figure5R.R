if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=1000),
  make_option(c("-d", "--desparsified"), action="store_true", default=FALSE),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations
desparsified <- opt$desparsified

methods <- c("rlp", "selectiveinference")
if (desparsified) methods <- c(methods, "desparsified0")

results_lookup <- expand.grid(
  method = methods,
  n = c(50, 100, 400)
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/original/laplace_autoregressive_0_{results_lookup[i,'n']}_101_gaussian_100_{results_lookup[i,'method']}.rds"))
}
results <- bind_rows(results) %>%
  mutate(
    method = method_labels[method]
  )

results_per_sim <- results %>%
  group_by(method, n, iteration) %>%
  mutate(index = 1:n()) %>%
  ungroup() %>%
  filter(index == 1) %>%
  dplyr::select(method, n, time)

results <- results %>%
  mutate(n = factor(n, levels = c(50, 100, 400)))

results_per_sim <- results_per_sim %>%
  mutate(n = factor(n, levels = c(50, 100, 400)))

colors <- colors[1:3]

fill_scale <- scale_fill_manual(
  values = colors,
  name = "Sample Size",
  labels = c("50", "100", "400")
)

color_scale <- scale_color_manual(
  values = colors,
  name = "Sample Size",
  labels = c("50", "100", "400")
)

wrap <- function(x) str_wrap(x, width = 12)

## Coverage
p1 <- results %>%
  filter(!is.na(estimate)) %>%
  mutate(covered = lower <= truth & upper >= truth) %>%
  group_by(method, iteration, n) %>%
  summarise(coverage = mean(covered, na.rm = TRUE)) %>%
  ungroup() %>%
  ggplot(aes(x = method, y = coverage, fill = n)) +
  geom_violin(color = NA) +
  geom_hline(yintercept = 0.8) +
  fill_scale +
  ylab("Coverage") +
  xlab("Method") +
  theme_minimal() +
  scale_x_discrete(labels = wrap)

p2 <- results_per_sim %>%
  group_by(method, n) %>%
  summarise(avg_runtime = mean(time)) %>%
  ggplot(aes(x = method, y = avg_runtime, fill = n, color = n)) +
  geom_col(position = "dodge") +
  fill_scale + color_scale +
  ylab("Avg Time (s)") +
  xlab("Method") +
  theme_minimal() +
  guides(color = "none") +
  scale_x_discrete(labels = wrap)

p3 <- results %>%
  mutate(width = upper - lower) %>%
  group_by(method, n) %>%
  summarise(width = median(width, na.rm = TRUE)) %>%
  ungroup() %>%
  ggplot(aes(x = method, y = width, fill = n)) +
  geom_col(position = "dodge") +
  fill_scale +
  ylab(expression(`Med Width`)) +
  xlab("Method") +
  theme_minimal() +
  coord_cartesian(ylim = c(0, 20)) +
  scale_x_discrete(labels = wrap)


if (interactive()) {
  pdf("out/figure5R.pdf", height = 3.3, width = 4.2)
} else {
  pdf("code/out/figure5R.pdf", height = 3.3, width = 4.2)
}
(p1 / p3 / p2) + plot_layout(guides = "collect", axes = "collect")
dev.off()
