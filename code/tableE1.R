if (interactive()) {
  source("setup.R")
  path_pre <- glue("out/")
} else {
  source("code/setup.R")
  path_pre <- glue("code/out/")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=1000),
  make_option(c("--loc"), type="character", default=glue("{res_dir}/"))
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations

results_lookup <- expand.grid(
  method = c("rlp", "rmp")
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/original/sparse1_autoregressive_0_100_101_gaussian_100_{results_lookup[i,'method']}.rds"))
}
res <- bind_rows(results) %>%
  mutate(
    method = method_labels[method]
  )

tab <- res %>%
  mutate(
    abs_truth = abs(truth),
    covered = lower <= truth & upper >= truth
  ) %>%
  group_by(method, abs_truth) %>%
  summarise(coverage = glue("{round(mean(covered), 3)*100}%"), .groups = "drop") %>%
  pivot_wider(names_from = method, values_from = coverage)


# Render only the tabular (no table env), write to file
out_file <- glue("{path_pre}tableE1.tex")

# write the kable as before
colnames(tab)[1] <- "beta"
kbl(
  tab,
  format    = "latex",
  booktabs  = TRUE,
  align     = rep("c", ncol(tab)),
  escape    = TRUE,
  sanitize.colnames.function = identity,
  digits    = 3,
  table.envir = NULL,
  linesep     = ""
) %>%
  add_header_above(c(" " = 1, "Coverage (%)" = 2)) %>%
  write(out_file)

# now read it back, replace "beta" with "$|\\beta|$" and overwrite
tex <- readLines(out_file)
tex <- gsub("\\bbeta\\b", "\\$|\\\\beta|\\$", tex)
writeLines(tex, out_file)

