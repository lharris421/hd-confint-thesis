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

res <- readRDS(glue("{opt$loc}rds/{iterations}/original/multiple.rds"))

set.seed(1234)
coverage_labels <- res %>%
  group_by(iteration) %>%
  filter(row_number() <= 10) %>%
  ungroup() %>%
  mutate(covered = lower <= truth & truth <= upper) %>%
  group_by(variable) %>%
  summarise(coverage = mean(covered)) %>%
  mutate(label = glue::glue("{round(coverage, 3)*100}%"))

gg1 <- res %>%
  group_by(iteration) %>%
  filter(row_number() <= 10) %>%
  ungroup() %>%
  mutate(covered = lower <= truth & truth <= upper) %>%
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
  theme(
    legend.position = "none"
  ) +
  ylab(NULL) +
  xlab(NULL) +
  facet_grid(~ variable) +
  geom_text(
    data = coverage_labels,
    aes(x = -Inf, y = Inf, label = label),
    hjust = -0.25, vjust = 1,
    inherit.aes = FALSE,
    size = 3
  ) + coord_cartesian(ylim = c(-4, 4))

r_it <- sample(res$iteration, 1)
gg2 <- res %>%
  filter(iteration == r_it) %>%
  filter(row_number() <= 10) %>%
  ggplot(aes(x = variable, y = coef)) +
  geom_point() +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = .1) +
  theme_minimal() +
  xlab("") + ylab("Estimate (80% CI)") +
  coord_cartesian(ylim = c(-4, 4))

if (interactive()) {
  pdf("out/figure7-man3.pdf", height = 5, width = 6.5)
} else {
  pdf("code/out/figure7-man3.pdf", height = 5, width = 6.5)
}
gg1 / gg2
dev.off()

