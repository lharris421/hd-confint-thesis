if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

# Define the penalty functions
lasso_penalty <- function(beta, lambda) {
  lambda * abs(beta)
}

mcp_penalty <- function(beta, lambda, gamma = 3) {
  abs_beta <- abs(beta)
  ifelse(abs_beta <= gamma * lambda,
         lambda * abs_beta - (abs_beta^2) / (2 * gamma),
         0.5 * gamma * lambda^2)
}

scad_penalty <- function(beta, lambda, gamma = 3.7) {
  abs_beta <- abs(beta)
  ifelse(abs_beta <= lambda,
         lambda * abs_beta,
         ifelse(abs_beta < gamma * lambda,
                (2 * gamma * lambda * abs_beta - abs_beta^2 - lambda^2) / (2 * (gamma - 1)),
                0.5 * lambda^2 * (gamma + 1)))
}

# Generate beta values
beta_vals <- seq(-4, 4, length.out = 401)
beta_vals_half <- seq(0.01, 4, length.out = 200)
lambda <- 1  # Set lambda for visualization

# Compute penalties
penalty_data <- data.frame(
  beta = rep(beta_vals, 3),
  Penalty = c(
    sapply(beta_vals, lasso_penalty, lambda),
    sapply(beta_vals, mcp_penalty, lambda, gamma = 3),
    sapply(beta_vals, scad_penalty, lambda, gamma = 3.7)
  ),
  Type = rep(c("Lasso", "MCP", "SCAD"), each = length(beta_vals))
)

# Plot using ggplot
gg <- ggplot(penalty_data, aes(x = beta, y = Penalty, color = Type)) +
  geom_line(linewidth = 1) +
  labs(title = "", color = "Penalty",
       x = "Beta", y = "Penalty") +
  theme_minimal()

if (interactive()) {
  pdf("out/figure4-man3.pdf", height = 2.5, width = 3.9)
} else {
  pdf("code/out/figure4-man3.pdf", height = 2.5, width = 3.9)
}
gg
dev.off()

