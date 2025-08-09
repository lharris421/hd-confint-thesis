if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=1000),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations

results <- readRDS(glue("{opt$loc}rds/{iterations}/bias_decomposition.rds"))

plots <- bias_decomp_plots(results, params)
plots[[1]]  <- plots[[1]]  + coord_cartesian(xlim = c(-0.1, 0.1))
plots[[2]]  <- plots[[2]]  + coord_cartesian(xlim = c(-0.1, 0.1))
plots[[3]]  <- plots[[3]]  + coord_cartesian(xlim = c(-0.1, 0.1))

# Create density plots using ggplot2
if (interactive()) {
  pdf("out/figureF2.pdf", height = 3.3, width = 6.5)
} else {
  pdf("code/out/figureF2.pdf", height = 3.3, width = 6.5)
}
plots[[3]] / plots[[2]] / plots[[1]] +
  patchwork::plot_layout(guides = "collect", axes = "collect")
dev.off()
