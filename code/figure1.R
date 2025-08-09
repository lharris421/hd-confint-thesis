if (interactive()) {
  source("setup.R")
} else {
  source("code/setup.R")
}

option_list <- list(
  make_option(c("--iterations"), type="integer", default=100),
  make_option(c("--seed"), type="double", default=1234),
  make_option(c("--loc"), type="character", default="")
)
opt <- parse_args(OptionParser(option_list=option_list))
iterations <- opt$iterations
seed <- opt$seed

results <- readRDS(glue("{opt$loc}rds/{iterations}/gam/laplace_autoregressive_0_100_101_gaussian_100_rlp.rds"))

line_data <- results %>%
  mutate(method = method_labels[method])

cutoff <- max(line_data$x)
xvals <- seq(from = -cutoff, to = cutoff, length.out = cutoff * 100 + 1)
density_data <- data.frame(x = xvals, density = 2 * dlaplace(xvals, rate = 1.414))

p1 <- ggplot() +
  geom_line(data = line_data, aes(x = x, y = y, color = method)) +
  geom_hline(data = line_data, aes(yintercept = average_coverage, color = method), linetype = 2) +
  geom_hline(aes(yintercept = 0.8), linetype = 1, alpha = .5) +
  geom_area(data = density_data, aes(x = x, y = density / max(density)), fill = "grey", alpha = 0.5) +
  theme_minimal() +
  xlab(expression(beta)) +
  ylab("Estimated Coverage") +
  coord_cartesian(ylim = c(0, 1)) +
  scale_color_manual(name = "Method", values = colors) +
  theme(legend.position = "none")


## Ridge
## Set parameters
alpha <- 0.2
prior_mean <- 0
prior_variance <- 1^2
sigma2 <- 1^2     # Likelihood variance
n <- 1         # Sample size
theta_values <- seq(-3, 3, length.out = 1000)  # Range of theta values
z <- qnorm(1 - alpha / 2)

# Calculate prior and likelihood precisions
precision_prior <- 1 / prior_variance
precision_likelihood <- n / sigma2
precision_post <- precision_prior + precision_likelihood

# Posterior variance (for credible interval)
sigma2_post <- 1 / precision_post
sigma_post <- sqrt(sigma2_post)

# Weights
prior_weight <- precision_prior / precision_post
lik_weight <- 1 - prior_weight

# Mean difference between posterior mean and true theta
posterior_mean <- prior_weight * prior_mean + lik_weight * theta_values
sd_mu_post <- sqrt(lik_weight^2 * (sigma2 / n))

# Compute coverage probability analytically (centering at zero for ease of computation)
upper_limit <- (posterior_mean + z * sigma_post)
lower_limit <- (posterior_mean - z * sigma_post)

coverage_probs <- pnorm(theta_values, upper_limit, sd = sd_mu_post, lower.tail = FALSE) - pnorm(theta_values, lower_limit, sd = sd_mu_post, lower.tail = FALSE)

## prior dens
prior_dens <- dnorm(theta_values, sd = sqrt(prior_variance))

# Plot coverage probability vs theta
data <- data.frame(
  theta_values = theta_values,
  coverage_probs = coverage_probs,
  prior_dens_scaled = prior_dens / max(prior_dens)  # Scale prior density for plotting
)

# Calculate horizontal lines
coverage_avg <- sum(prior_dens * coverage_probs) / sum(prior_dens)
threshold <- 1 - alpha

# Plot using ggplot2
p2 <- ggplot(data, aes(x = theta_values)) +
  geom_line(aes(y = coverage_probs), color = "green3") +  # Line for coverage_probs
  geom_ribbon(aes(ymin = 0, ymax = prior_dens_scaled), fill = "grey", alpha = 0.5) +  # Shaded region for prior_dens
  geom_hline(yintercept = threshold, color = "black") +  # Horizontal line at 1 - alpha
  geom_hline(yintercept = coverage_avg, color = "green3", linetype = "dashed") +  # Horizontal line for weighted avg
  labs(x = expression(theta), y = "Coverage Probability") +
  ylim(0, 1) +  # Set y-axis limits
  theme_minimal()  # Minimal theme for clarity

if (interactive()) {
  pdf("out/figure1.pdf", height = 2.6, width = 5.2)
} else {
  pdf("code/out/figure1.pdf", height = 2.6, width = 5.2)
}
p2 + p1 + patchwork::plot_layout(axes = "collect")
dev.off()
