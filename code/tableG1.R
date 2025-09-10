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

res <- readRDS(glue("{opt$loc}rds/{iterations}/stability_selection.rds"))

orig_prob <- colMeans(res[["orig"]])
boot_prob <- colMeans(res[["boot"]])

tbl <- tibble(
  Predictor = paste0("BETA_", seq_along(orig_prob)),  # placeholder: BETA_1, BETA_2, …
  Original  = orig_prob,
  Bootstrap = boot_prob
)

out_file <- glue("{path_pre}tableG1.tex")

# 2) render with a spanning header but leave the body & colnames escaped
kbl(
  tbl,
  format    = "latex",
  booktabs  = TRUE,
  align     = rep("c", ncol(tbl)),
  escape    = TRUE,
  sanitize.colnames.function = identity,
  digits    = 3,
  table.envir = NULL,
  linesep     = ""
) %>%
  add_header_above(c(" " = 1, "Inclusion Probability" = 2)) %>%
  write(out_file)

# 3) post‑process: read back and swap each placeholder for real LaTeX
tex <- readLines(out_file)
for (i in seq_along(orig_prob)) {
  # pattern = literal “BETA\_i”, so use fixed = TRUE
  tex <- gsub(
    paste0("BETA\\_", i),
    paste0("$\\beta_{", i, "}$"),
    tex,
    fixed = TRUE
  )
}
writeLines(tex, out_file)
