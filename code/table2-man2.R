if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=100),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations

results_lookup <- expand.grid(
  method = c("desparsified", "selectiveinference", "rl", "pipep", "lqap")
)

results <- list()
for (i in 1:nrow(results_lookup)) {
  results[[i]] <- readRDS(glue("{opt$loc}rds/{iterations}/original/bias_v_debias_{results_lookup[i,'method']}.rds"))
}
comb <- bind_rows(results) %>%
  mutate(
    method = method_labels[method]
  )


summ <- comb %>%
  mutate(
    covered = lower <= truth & truth <= upper,
    width   = upper - lower,
    sig = lower > 0 | upper < 0
  ) %>%
  group_by(scenario, method, iteration) %>%
  summarise(
    coverage_selected = sum(covered & selected) / sum(selected),
    width             = median(width[selected], na.rm = TRUE),
    power = sum(sig & truth != 0) / sum(truth != 0),
    t1 = sum(sig & truth == 0) / sum(truth == 0),
    .groups = "drop"
  ) %>%
  group_by(scenario, method) %>%
  summarise(
    sd_coverage       = sd(coverage_selected, na.rm = TRUE),
    IQRc                = quantile(coverage_selected, .75, na.rm = TRUE) - quantile(coverage_selected, .25, na.rm = TRUE),
    coverage_selected = mean(coverage_selected, na.rm = TRUE),
    q1                = quantile(width, .25, na.rm = TRUE),
    q3                = quantile(width, .75, na.rm = TRUE),
    width             = median(width, na.rm = TRUE),
    power = mean(power, na.rm = TRUE),
    t1 = mean(t1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ## prettify names and build display strings ----------------------------------
mutate(
  method = method %>%
    str_replace_all("_", " ") %>% str_to_title() %>%
    str_replace("Pipe", "PIPE")   %>%
    str_replace("Lqa", "LQA")   %>%
    str_replace("Mcp",  "MCP")    %>%
    str_replace("Scad",  "SCAD"),
  coverage_str = sprintf(
    "%.1f\\%% (%.1f\\%%)",
    coverage_selected * 100,
    sd_coverage       * 100
  ),
  width_str = sprintf(
    "%.3f (%.3f, %.3f)",
    width, q1, q3
  ),
  power = power,
  t1 = t1,
  method = case_when(
    str_detect(method, "Adj") ~ str_remove(str_replace(method, "PIPE", "LQA"), " Adj"),
    TRUE ~ method
  )
) %>%
  select(method, scenario, coverage_str, width_str)

print(summ)

tbl <- summ %>%
  filter(!str_detect(method, "MCP"))  %>%
  filter(!str_detect(method, "SCAD"))  %>%
  mutate(method = factor(method, levels = c("Desparsified Lasso", "Selective Inference", "Relaxed Lasso", "PIPE Posterior", "LQA Posterior"))) %>%
  arrange(scenario, method)


bounds <- tbl %>%
  mutate(row_id = row_number()) %>%
  group_by(scenario) %>%
  summarise(start = first(row_id),
            end   = last(row_id),
            .groups = "drop")

k <- tbl %>%
  select(-scenario) %>%
  kbl(format      = "latex",
      booktabs    = TRUE,
      align       = c("lcc"),
      linesep     = "",
      escape      = FALSE,
      col.names   = c("Method",
                      "Coverage (mean, sd)",
                      "Width (median, Q1--Q3)"))

n_cols <- ncol(tbl) - 1           # minus the scenario column we dropped

for (i in seq_len(nrow(bounds))) {
  k <- k %>% group_rows(group_label      = glue("Scenario {bounds$scenario[i]}"),
                        start_row  = bounds$start[i],
                        end_row    = bounds$end[i],
                        escape     = FALSE,
                        colnum     = n_cols)       # ← key fix
}

if (interactive()) {
  path_pre <- "out/"
} else {
  path_pre <- "code/out/"
}
write(k, glue('{path_pre}/table2-man2.tex'))
