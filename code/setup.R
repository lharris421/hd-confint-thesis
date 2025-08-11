# Clear enviornment
rm(list=ls())

packages <- c(
  "ncvreg", "hdrm", "hdi", "selectiveInference", "glmnet",
  "dplyr", "tidyr", "purrr", "stringr", "ggplot2", "glue",
  "kableExtra", "patchwork", "mgcv", "progress", "optparse",
  "grid", "scales"
)
quietlyLoadPackage <- function(package) {
  suppressPackageStartupMessages(library(package, character.only = TRUE))
}
lapply(packages, quietlyLoadPackage)

res_dir <- switch(Sys.info()['user'],
                  'pbreheny' = '~/res/lasso-confint',
                  'loganharris' = '~/github/lasso-confint')
devtools::load_all(res_dir, quiet = TRUE)

method_labels <- c(
  "selectiveinference" = "Selective Inference",
  "desparsified"       = "Desparsified Lasso",
  "desparsified0"      = "Desparsified Lasso",
  "ridge"              = "Ridge Posterior",
  "ridgeT"             = "Ridge Posterior",
  "ridgeboot"          = "Ridge Bootstrap",
  "ridgebootT"         = "Ridge Bootstrap",
  "rlp"                = "RL Posterior",
  "rmp"                = "RM Posterior",
  "traditional"        = "Traditional Bootstrap",
  "pipep"              = "PIPE Posterior",
  "pipepmcp"           = "PIPE Posterior (MCP)",
  "pipepscad"          = "PIPE Posterior (SCAD)",
  "pipepenet"          = "Elastic Net",
  "lqapenet"           = "Elastic Net (LQA)",
  "lqap"               = "LQA Posterior",
  "lqapmcp"            = "LQA Posterior (MCP)",
  "lqapscad"           = "LQA Posterior (SCAD)",
  "rl"                 = "Relaxed Lasso"
)

## Plot colors
colors <- palette()[c(2, 4, 3, 6, 7, 5)]
sec_colors <- c("black", "grey62")
background_colors <- c("#E2E2E2", "#F5F5F5")
