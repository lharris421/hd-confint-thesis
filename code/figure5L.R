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


methods <- c("rlp", "selectiveinference")
if (desparsified) methods <- c(methods, "desparsified0")

results_lookup <- expand.grid(
  method = methods
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/gam/laplace_autoregressive_0_100_101_gaussian_100_{results_lookup[i,'method']}.rds"))
}
line_data <- bind_rows(results) %>%
  mutate(
    method = method_labels[method]
  )

cutoff <- max(line_data$x)
xvals <- seq(from = -cutoff, to = cutoff, length.out = cutoff * 100 + 1)
density_data <- data.frame(x = xvals, density = 2 * dlaplace(xvals, rate = 1.414))

p1 <- ggplot() +
  geom_line(data = line_data, aes(x = x, y = y, color = method)) +
  geom_hline(data = line_data, aes(yintercept = average_coverage, color = method), linetype = 2) +
  geom_hline(aes(yintercept = 0.8), linetype = 1, alpha = .5) +
  geom_area(data = density_data, aes(x = x, y = density / max(density)), fill = "grey", alpha = 0.5) +
  theme_minimal() +
  xlab(expression(beta)) +
  ylab("Estimated Coverage") +
  coord_cartesian(ylim = c(0, 1)) +
  scale_color_manual(name = "Method", values = colors) +
  guides(
    colour = guide_legend(
      title = "Method",
      nrow = 3,
      position = "top",
      theme(
        legend.title.position = "top",
        legend.key.height = unit(0, "in")
      )
    ),
  )

if (interactive()) {
  pdf("out/figure5L.pdf", height = 3.1, width = 2.2)
} else {
  pdf("code/out/figure5L.pdf", height = 3.1, width = 2.2)
}
p1
dev.off()
