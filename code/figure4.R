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

results_lookup <- expand.grid(
  method = c("rlp", "ridge")
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/original/highcorr_{results_lookup[i,'method']}.rds"))
}
results <- bind_rows(results) %>%
  mutate(
    estimate = ifelse(method == "rlp", coef, estimate),
    method = method_labels[method]
  )

plots <- list()
methods <- unique(results_lookup$method)
set.seed(1234)
selected_example <- sample(1:iterations, 1)
for (i in 1:length(unique(results$method))) {

  curr_method <- unique(results$method)[i]

  tmp_results <- results %>%
    filter(method == curr_method) %>%
    mutate(
      variable = ifelse(variable == "A1", "A", variable),
      variable = ifelse(variable == "B1", "B", variable),
    )

  example_res <- tmp_results %>%
    filter(iteration == selected_example) %>%
    filter(variable %in% c("A", "B", glue::glue("N{1:18}")))

  pdat <- tmp_results %>%
    filter(variable %in% c("A", "B", "N1")) %>%
    mutate(covered = lower <= truth & truth <= upper)

  pdat$variable <- factor(pdat$variable, levels = c("N1", "B", "A"))

  coverage_labels <- pdat %>%
    group_by(variable) %>%
    summarise(coverage = mean(covered)) %>%
    mutate(label = glue::glue("{round(coverage, 3)*100}%"))

  plots[[1 + 2*(i-1)]] <- pdat %>%
    mutate(variable = factor(variable, levels = c("A", "B", "N1"))) %>%
    mutate(midpoint = (lower + upper) / 2) %>%
    group_by(variable) %>%
    arrange(midpoint) %>%
    mutate(xorder = row_number()) %>%
    ungroup() %>%
    ggplot() +
    geom_errorbar(aes(x = xorder, ymin = lower, ymax = upper, color = covered, width = 0)) +
    scale_color_manual(values = c("TRUE" = "black", "FALSE" = "red")) +
    geom_hline(aes(yintercept = truth), color = "gold", linetype = "dashed") +
    theme_minimal() +
    xlab("") +
    theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) +
    coord_cartesian(ylim = c(-2, 2)) +
    theme(
      legend.position = "none"
    ) +
    ggtitle(curr_method) +
    facet_grid(~ variable) +
    geom_text(
      data = coverage_labels,
      aes(x = -Inf, y = Inf, label = label),
      hjust = -0.5, vjust = 1,
      inherit.aes = FALSE,
      size = 4
    ) +
    xlab("Iterations") +
    ylab("80% CI")

  plots[[2 + 2*(i-1)]] <- example_res %>%
    mutate(variable = factor(variable, levels = rev(c("A", "B", glue::glue("N{1:18}"))))) %>%
    ggplot() +
    geom_errorbar(aes(xmin = lower, xmax = upper, y = variable)) +
    geom_point(aes(x = estimate, y = variable)) +
    theme_minimal() +
    coord_cartesian(xlim = c(-2, 2)) +
    ylab(NULL) +
    xlab("Estimate (80% CI)")

}

if (interactive()) {
  pdf("out/figure4.pdf", height = 5.6, width = 5.2)
} else {
  pdf("code/out/figure4.pdf", height = 5.6, width = 5.2)
}
(plots[[3]] + plots[[1]] + patchwork::plot_layout(axes = "collect")) /
  (plots[[4]] + plots[[2]] + patchwork::plot_layout(axes = "collect"))
dev.off()

