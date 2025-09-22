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
  method = c("rlp", "rmp", "rsp")
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
    coverage_true = sum(covered & truth != 0) / sum(truth != 0),
    width             = median(width[selected], na.rm = TRUE),
    power = sum(sig & truth != 0) / sum(truth != 0),
    t1 = sum(sig & truth == 0) / sum(truth == 0),
    selected = sum(selected),
    .groups = "drop"
  ) %>% filter(selected != 0) %>%
  group_by(scenario, method) %>%
  summarise(
    sd_coverage       = sd(coverage_selected, na.rm = TRUE),
    coverage_selected = mean(coverage_selected, na.rm = TRUE),
    coverage_true = mean(coverage_true, na.rm = TRUE),
    q1                = quantile(width, .25, na.rm = TRUE),
    q3                = quantile(width, .75, na.rm = TRUE),
    width             = median(width, na.rm = TRUE),
    power = mean(power, na.rm = TRUE),
    t1 = mean(t1, na.rm = TRUE),
    selected = mean(selected),
    .groups = "drop"
  ) %>%
  ungroup() %>%
  ## prettify names and build display strings ----------------------------------
mutate(
  method = method %>%
    str_replace_all("_", " ") %>% str_to_title() %>%
    str_replace("Lqa", "LQA")   %>%
    str_replace("Rl", "RL")   %>%
    str_replace("Rs", "RS")   %>%
    str_replace("Rm", "RM")   %>%
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
  selected = sprintf("%.1f", selected),
  power = power,
  t1 = t1
) %>%
  select(method, selected, scenario, coverage_str, width_str)

tbl <- summ %>%
  mutate(method = factor(method, levels = c("RL Posterior", "RM Posterior", "RS Posterior"))) %>%
  arrange(scenario, method)

bounds <- tbl %>%
  mutate(row_id = row_number()) %>%
  group_by(scenario) %>%
  summarise(start = first(row_id),
            end   = last(row_id),
            .groups = "drop")

hdr <- c(
  "Method",
  "\\shortstack{Average\\\\Selected}",
  "\\shortstack{Coverage\\\\(mean, sd)}",
  "\\shortstack{Width\\\\(median, Q1--Q3)}"
)
k <- tbl %>%
  select(-scenario) %>%
  kbl(format      = "latex",
      booktabs    = TRUE,
      align       = c("lccc"),
      linesep     = "",
      escape      = FALSE,
      col.names   = hdr)

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
write(k, glue('{path_pre}/tableB1-man3.tex'))
