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

tmp <- data.frame(
  p = c(20, 100, 200),
  SNR = c(19, 115, 239)
)
results_lookup <- bind_rows(
  tmp %>% mutate(method = "ridgeT"),
  tmp %>% mutate(method = "ridgebootT")
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/gam/normal_autoregressive_0_200_{results_lookup[i,'p']}_gaussian_{results_lookup[i,'SNR']}_{results_lookup[i,'method']}.rds"))
}
results <- bind_rows(results) %>%
  mutate(method = method_labels[method])

plots <- list()
for (j in 1:length(unique(results$p))) {

  which_p <- unique(results$p)[j]
  line_data <- results %>% filter(p == which_p)

  sd <- sqrt(1 / 0.8)
  cutoff <- sd * 3
  xvals <- seq(from = -cutoff, to = cutoff, length.out = 101)
  density_data <- data.frame(x = xvals, density = dnorm(xvals, sd = sd))
  density_data <- bind_rows(
    density_data
  )

  plots[[j]] <- ggplot() +
    geom_line(data = line_data , aes(x = x, y = y, color = method)) +
    geom_hline(data = line_data, aes(yintercept = average_coverage, color = method), linetype = 2) +
    geom_area(data = density_data, aes(x = x, y = density / max(density)), fill = "grey", alpha = 0.5, inherit.aes = FALSE) +
    theme_minimal() +
    xlab(expression(beta)) +
    ylab("Coverage") +
    coord_cartesian(ylim = c(0, 1), xlim = c(-cutoff, cutoff)) +
    scale_color_manual(name = "Method", values = colors) +
    geom_hline(yintercept = 0.8) +
    ggtitle(glue("p = {which_p}"))

}

if (interactive()) {
  pdf("out/figureF1.pdf", height = 3, width = 6)
} else {
  pdf("code/out/figureF1.pdf", height = 3, width = 6)
}
full   <- wrap_plots(plots, ncol = 3)

# then do one global collect of legends, axis‐titles, and axes
full + plot_layout(
  guides      = "collect",
  axis_titles = "collect",
  axes        = "collect"
)
dev.off()
