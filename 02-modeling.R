################################################################################
# Project: Multidimensional capabilities index
# Author: Brian Beadle
# Last update: 17.03.26
################################################################################

# Clear environment and load packages
rm(list = ls())                     
library(psych)
library(haven)
library(lavaan)
library(brms)
library(bayesplot)
library(rstanarm)
library(irr)
library(dplyr)
library(tidyr)
library(tidyverse)
library(tidySEM)
library(tidybayes)
library(knitr)
library(nFactors)
library(grid)
library(gridExtra)
library(viridis)
library(qgraph)
library(xtable)
library(future)

# Set options
options(xtable.floating = FALSE)
options(xtable.timestamp = "")
options(future.globals.maxSize = 20 * 1024^3)

# SET YOUR DIRECTORY HERE!!!
setwd("")

# Loading data
d <- read_dta("ruwell-final-wide.dta")

# Specifying ordered factors for the y variables (potential items in the model)
for (var in paste0("y", 1:38)) {
  d[[var]] <- factor(d[[var]], levels = 1:5, ordered = TRUE)
}

################################################################################
# Factor analyses
################################################################################

# Subsetting variables for factor analysis (all y variables)
vars <- d[, paste0("y", 1:38)]

# Computing polychoric correlation matrix 
polychoric_corr <- polychoric(vars)$rho

# Conducting Bartletts test of sphericity
cortest.bartlett(polychoric_corr, n = nrow(d))

# Running KMO test
KMO(polychoric_corr)

# Fitting an EFA with 3 factors
fa3 <- fa(
  r = polychoric_corr,
  nfactors = 3,
  fm = "mle",
  rotate = "varimax"
)

# Displaying the factor loadings and summarizing results
print(fa3$loadings)
summary(fa3)
cat("Explained Variance")
print(fa3$Vaccounted)

# Preparing the data for CFA
y_vars <- paste0("y", 1:38)

for (var in y_vars) {
  d[[var]] <- factor(d[[var]], 
                     levels = sort(unique(d[[var]])), 
                     ordered = TRUE) # Converting to ordered factors
}

vars <- d[, y_vars] # Sub-setting the data

# Setting row and column names
rownames(polychoric_corr) <- y_vars
colnames(polychoric_corr) <- y_vars

# Defining the CFA model
cfa_model <- '
  social =~ y1 + y35 + y37 + y38
  personal =~ y6 + y9 + y12 + y24 + y27
  environmental =~ y20 + y21 + y22
  
  social =~ y24
  social =~ y6
  social =~ y22
  personal =~ y20
'
# Fitting the CFA model
fit1 <- cfa(cfa_model, sample.cov = polychoric_corr, sample.nobs = nrow(d))

summary(fit1, fit.measures = TRUE, standardized = TRUE) # Model summary

# Extracting factor correlations with standard errors from full sample model
cor_full <- parameterEstimates(fit1, 
                               standardized = TRUE) %>%
  filter(op == "~~",
         lhs != rhs,
         lhs %in% c("social", "personal", "environmental"),
         rhs %in% c("social", "personal", "environmental"))

print(cor_full)

# Cross-validation test
set.seed(82)                                
n <- nrow(d)  
train <- sample(1:n, size = round(0.7 * n))  

d_train <- d[train, ]
d_validate <- d[-train, ]

fit_train <- cfa(cfa_model, 
                 data = d_train, 
                 estimator = "WLSMV",  
                 ordered = TRUE) 

fit_validation <- cfa(cfa_model, 
                      data = d_validate, 
                      estimator = "WLSMV", 
                      ordered = TRUE, 
                      mimic = "lavaan")

summary(fit_train)
summary(fit_validation)

# Extracting fit indices for training and validation models
fit_train_indices <- fitMeasures(fit_train, 
                                 c("cfi", "tli", "rmsea", "srmr"))
fit_validation_indices <- fitMeasures(fit_validation, 
                                      c("cfi", "tli", "rmsea", "srmr"))

print(fit_train_indices)
print(fit_validation_indices)

# Extracting factor correlations with standard errors from training model
cor_train <- parameterEstimates(fit_train, 
                                standardized = TRUE) %>%
  filter(op == "~~",          # covariance/correlation operators
         lhs != rhs,          # exclude variances (keep covariances only)
         lhs %in% c("social", "personal", "environmental"),
         rhs %in% c("social", "personal", "environmental"))

# Extracting factor correlations with standard errors from validation model
cor_validation <- parameterEstimates(fit_validation, 
                                     standardized = TRUE) %>%
  filter(op == "~~",
         lhs != rhs,
         lhs %in% c("social", "personal", "environmental"),
         rhs %in% c("social", "personal", "environmental"))

print(cor_train)
print(cor_validation)

# Cleaning up environment before starting next section
rm(cor_full, cor_train, cor_validation, d_train, d_validate, fa3, 
   fit_train, fit_validation, fit1, cfa_model, fit_train_indices, 
   fit_validation_indices, n, train, y_vars, vars, var)

################################################################################
# Summary statistics and data transformations
################################################################################

# Formatting covariates and id number
d$female <- as.factor(d$female)
d$id <- as.factor(d$id)            
d$country <- factor(d$country, 
                    labels = c("Albania", "Kosovo", "Moldova", "Romania"))
d$age <- as.numeric(d$age)

# Defining variable lists to reference later 
covariates <- c("country", "age", "female")
vars_keep <- c(
  "y1", "y35", "y37", "y38",            # Social
  "y6", "y9", "y12", "y24", "y27",      # Personal
  "y20", "y21", "y22"                   # Environmental
)

# Mapping the response variables to numeric dimensions
dimension_mapping <- tibble(
  original_item = c(
    "y1", "y35", "y37", "y38",          # Social
    "y6", "y9", "y12", "y24", "y27",    # Personal
    "y20", "y21", "y22"                 # Environmental
  ),
  dimension = c(
    rep(1, 4),  
    rep(2, 5),  
    rep(3, 3)
  )
)

# The next block of code performs the following primary functions:
#  1. Drops variables that are not used for the models
#  2. Specifies response variables as numeric
#  3. Renumbers response variables to be consecutive
#  4. Generates a variable 'item' 
d <- d %>%
  select(id, all_of(covariates), all_of(vars_keep)) %>%
  pivot_longer(
    cols = all_of(vars_keep),         # Specify the columns to pivot
    names_to = "original_item",       # Track original item name
    values_to = "y"                   # Response variable
  ) %>%
  mutate(
    y = as.numeric(y),                # Remove labels from `y`
    item = dense_rank(original_item)  # Renumber items consecutively
  ) %>%
  left_join(dimension_mapping, by = "original_item") %>%
  mutate(
    y = as.ordered(y),
    item = as.factor(item),           # Convert `item` to factor
    dimension = as.factor(dimension)  # Convert `dimension` to factor
  ) %>%
  arrange(id, item)                   # Ensure proper order

# Creating item labels for plots
item_labels <- c(
  "Belonging/inclusion in community",
  "Feels attached to village",
  "Feels no place compares to their village",
  "Feels village is best place for them",
  "Freedom of speech",
  "Self-rated overall health",
  "Condition of dwelling",
  "Equal access to education",
  "Self-rated financial security",
  "Quality of water bodies",
  "Quality of forests",
  "Quality of air"
)

head(d)

# Generating summary stats
summary_stats <- d %>%
  select(id, country, age, female) %>%
  distinct(id, .keep_all = TRUE) %>%
  group_by(country) %>%
  summarise(
    `n` = n(),
    `Age` = sprintf("%.2f (%.2f)", 
                    mean(age, na.rm = TRUE), 
                    sd(age, na.rm = TRUE)),
    `Female` = sprintf("%.2f%%", 
                       mean(as.numeric(as.character(female))) * 100),
    `Male` = sprintf("%.2f%%", 
                     (1 - mean(as.numeric(as.character(female)))) * 100)) %>%
  rename(Country = country)

# Calculating totals
totals <- d %>%
  summarise(
    `Country` = "Total",
    `n` = n(),
    `Age` = sprintf("%.2f (%.2f)", 
                    mean(age, na.rm = TRUE), 
                    sd(age, na.rm = TRUE)),
    `Female` = sprintf("%.2f%%", 
                       mean(as.numeric(as.character(female))) * 100),
    `Male` = sprintf("%.2f%%", 
                     (1 - mean(as.numeric(as.character(female)))) * 100)
  )

# Generating a complete table
final_table <- bind_rows(summary_stats, totals)
lat_tab1 <- xtable(final_table, 
                   caption = "Summary statistics by country", 
                   label = "tab:summ_stats")
addtorow <- list()
addtorow$pos <- list(nrow(final_table) - 1) 
addtorow$command <- "\\hline" 

# Exporting the table as a LaTeX file
print(lat_tab1, 
      file = "table1-summ_stats.tex", 
      include.rownames = FALSE,
      floating = TRUE,
      table.placement = "htbp",
      add.to.row = addtorow)

# Cleanup before next section
rm(addtorow, dimension_mapping, final_table, lat_tab1, 
   summary_stats, totals, vars_keep)

################################################################################
# Graded response model (the capabilities index)
################################################################################

# Model specifications (1pl and 2pl)
formula1pl <- bf(
  y ~ 1 + country + s(age, by = country, bs = "tp") + # Fixed effects 
    (1 + dimension | item) + (0 + dimension | id)     # Random effects terms
)

formula2pl <- bf(
  y ~ 1 + country + s(age, by = country, bs = "tp") + # Fixed effects 
    (1 + dimension | item) + (0 + dimension | id),    # Random effects terms
  disc ~ 1 + (1 | item)                               # Discrimination parameter
)

# Retrieving priors
get_prior(
  formula = formula2pl,
  data = d,
  family = brmsfamily("cumulative", "logit", threshold = "flexible")
)

# Specifying the priors for the 1PL and 2PL models
prior1pl <- 
  prior(lkj(1), class = "cor") +
  prior(normal(0, 5), class = "sd") +
  prior(normal(0, 5), class = "sds") +
  prior(normal(0, 5), class = "b") +
  prior(normal(0, 5), class = "Intercept")

prior2pl <- 
  prior(lkj(1), class = "cor") +
  prior(normal(0, 5), class = "sd") +
  prior(normal(0, 5), class = "sds") +
  prior(normal(0, 5), class = "b") +
  prior(normal(0, 5), class = "Intercept") +
  prior(normal(0, 1), class = "Intercept", dpar = "disc") 

# Fitting the models (note: VERY long run time!!!)
fit1pl <- brm(
  formula = formula1pl,
  data = d,  
  family = brmsfamily("cumulative", "logit", threshold = "flexible"),
  prior = prior1pl,
  cores = 4,  
  chains = 4,  
  iter = 3000,  
  warmup = 1500,
  control = list(adapt_delta = 0.99, max_treedepth = 15), 
  save_pars = save_pars(all = TRUE),
  refresh = 100,
  silent = FALSE,
  file = "02-ruwell-1PL.rds"
)

fit2pl <- brm(
  formula = formula2pl,
  data = d,  
  family = brmsfamily("cumulative", "logit", threshold = "flexible"),
  prior = prior2pl,
  cores = 4,  
  chains = 4,  
  iter = 3000,  
  warmup = 1500,
  control = list(adapt_delta = 0.99, max_treedepth = 15), 
  save_pars = save_pars(all = TRUE),
  refresh = 100,
  silent = FALSE,
  file = "02-ruwell-2PL.rds"
)

# Model summaries
summary(fit2pl)

# K-folds cross-validation (note: Also VERY long run time!!!)
id_folds <- d %>%
  distinct(id, country) %>%
  group_by(country) %>%
  mutate(fold = sample(rep(1:5, length.out = n()))) %>%
  ungroup() %>%
  select(id, fold)

d <- d %>% left_join(id_folds, by = "id")

if (!file.exists("kfold_1pl.rds")) {
  plan(multisession, workers = 5)
  kfold_1pl <- kfold(fit1pl, folds = d$fold, chains = 1, recompile = FALSE)
  plan(sequential)
  saveRDS(kfold_1pl, "kfold_1pl.rds")
} else {
  kfold_1pl <- readRDS("kfold_1pl.rds")
}

if (!file.exists("kfold_2pl.rds")) {
  plan(multisession, workers = 5)
  kfold_2pl <- kfold(fit2pl, folds = d$fold, chains = 1, recompile = FALSE)
  plan(sequential)
  saveRDS(kfold_2pl, "kfold_2pl.rds")
} else {
  kfold_2pl <- readRDS("kfold_2pl.rds")
}

# Comparing the models
loo_compare(kfold_1pl, kfold_2pl)

# Cleanup
rm(fit1pl, formula1pl, formula2pl, id_folds, kfold_1pl, kfold_2pl,
   prior1pl, prior2pl)

################################################################################
# Posterior predictive checks
################################################################################

# Bars chart
plot_ppc1 <- pp_check(fit2pl, type = "bars", ndraws = 100) + 
  labs(title = "Posterior predictive check (bars)")
ggsave("ppc-bars.pdf", 
       plot = plot_ppc1, width = 9, height = 6)
print(plot_ppc1)

# The empirical cumulative distribution function (ECDF)
plot_ppc2 <- pp_check(fit2pl, type = "ecdf_overlay", ndraws = 100) +
  labs(title = "Posterior predictive check (ECDF)")
ggsave("ppc-ecdf.pdf", 
       plot = plot_ppc2, width = 9, height = 6)
print(plot_ppc2)

# Predicted vs observed means and standard deviations (2d)
plot_ppc3 <- pp_check(fit2pl, 
                   type = "stat_2d", 
                   stat = c("mean", "sd"), 
                   ndraws = 1000) +  
  labs(title = "Posterior predictive check (2d stat)")
ggsave("ppc-2d.pdf", 
       plot = plot_ppc3, width = 9, height = 6)
print(plot_ppc3)

# Cleanup
rm(plot_ppc1, plot_ppc2, plot_ppc3)

################################################################################
# GRM results
################################################################################

# Extracting the random effects
ranef1 <- ranef(fit2pl)
str(ranef1)

# Estimating discrimination parameter
alpha <- ranef1$item[, , "disc_Intercept"] %>%
  exp() %>% 
  as_tibble() %>%
  rownames_to_column()

# Estimating easiness parameter
beta <- ranef1$item[, , "Intercept"] %>%
  as_tibble() %>%
  rownames_to_column()

# Combining easiness and disc parameters to one plot
plot_easidisc <- bind_rows(beta, alpha, .id = "nlpar") %>%
  rename(item = "rowname") %>%
  mutate(item = as.numeric(item)) %>%
  mutate(nlpar = factor(
    nlpar,
    labels = c("Easiness", "Discrimination")
  )) %>%
  ggplot(aes(item, Estimate, ymin = Q2.5, ymax = Q97.5)) +
  facet_wrap("nlpar", scales = "free_x") +
  geom_pointrange() +
  coord_flip() +
  labs(x = "") + 
  scale_x_discrete(limits = 1:12, labels = item_labels) +
  theme_minimal() 

ggsave("Fig1.pdf", 
       plot = plot_easidisc, width = 9, height = 6)
print(plot_easidisc)

# Predicted probabilities by country
plot_probs_country <- plot(
  conditional_effects(
    fit2pl, 
    re_formula = NULL,  
    categorical = TRUE, 
    prob = 0.8,
    effect = "country"
  ), 
  plot = FALSE)[[1]] +
  theme_minimal() +
  labs(
    x = "", 
    y = "Predicted probability"
  )

ggsave("Fig2.pdf", 
       plot = plot_probs_country, width = 9, height = 6)
print(plot_probs_country)

# Plotting conditional smooths (mu) for age by country
mu_fit2pl <- conditional_smooths(
  fit2pl,
  smooths = NULL,
  prob = 0.9
)

plot_data <- mu_fit2pl$mu

plot_mu_country <- ggplot(plot_data, 
                 aes(x = age, 
                     y = estimate__, 
                     color = country, 
                     fill = country)) +
  geom_ribbon(aes(ymin = lower__, ymax = upper__), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1) +
  coord_cartesian(ylim = c(-4, NA)) +
  labs(
    x = "Age", 
    y = "μ", 
    color = "Country", 
    fill = "Country") +
  theme_minimal()

ggsave("Fig3.pdf", 
       plot = plot_mu_country, width = 9, height = 6)
print(plot_mu_country)

# Cleanup
rm(alpha, beta, fit2pl, mu_fit2pl, plot_data, 
   plot_easidisc, plot_mu_country, plot_probs_country)

################################################################################
# Auxiliary regressions (latent trait models)
################################################################################

# Extracting the latent traits into a second (wide) data set
d2 <- d %>%
  select(id, all_of(covariates)) %>%
  distinct() %>%  # Keep only one row per person
  mutate(
    # Dimension-specific random effects
    theta_dim1 = ranef1$id[as.character(id), "Estimate", "dimension1"],
    theta_dim2 = ranef1$id[as.character(id), "Estimate", "dimension2"], 
    theta_dim3 = ranef1$id[as.character(id), "Estimate", "dimension3"],
    # Standard errors
    se_dim1 = ranef1$id[as.character(id), "Est.Error", "dimension1"],
    se_dim2 = ranef1$id[as.character(id), "Est.Error", "dimension2"],
    se_dim3 = ranef1$id[as.character(id), "Est.Error", "dimension3"]
  )

# Checking extraction results
head(d2)
nrow(d2)

# Social dimension model
formula_soc <- bf(
  theta_dim1 | se(se_dim1, sigma = TRUE) ~ 
    country + s(age, by = country, bs = "tp")
)

# Personal dimension model
formula_per <- bf(
  theta_dim2 | se(se_dim2, sigma = TRUE) ~ 
    country + s(age, by = country, bs = "tp")
)

# Environmental dimension model
formula_env <- bf(
  theta_dim3 | se(se_dim3, sigma = TRUE) ~ 
    country + s(age, by = country, bs = "tp")
)

# Building a global prior function for all models
get_prior(
  formula = formula_soc,
  data = d2,
  family = brmsfamily("gaussian")
) # Note: all dimensions were checked and can use the same prior set

prior_dims <- c(
  prior(normal(0, 5), class = "b"),
  prior(normal(0, 5), class = "sds"),
  prior(normal(0, 5), class = "Intercept"),
  prior(normal(0, 5), class = "sigma")
)

# Social model
fit_soc <- brm(
  formula = formula_soc,
  data = d2,
  family = brmsfamily("gaussian"),
  prior = prior_dims,
  chains = 4,
  iter = 4000,
  warmup = 2000,
  control = list(adapt_delta = 0.99),
  cores = parallel::detectCores(),
  file = "02-social.rds"
)

# Personal model
fit_per <- brm(
  formula = formula_per,
  data = d2,
  family = brmsfamily("gaussian"),
  prior = prior_dims,
  chains = 4,
  iter = 4000,
  warmup = 2000,
  control = list(adapt_delta = 0.99),
  cores = parallel::detectCores(),
  file = "02-personal.rds"
)

# Environmental model
fit_env <- brm(
  formula = formula_env,
  data = d2,
  family = brmsfamily("gaussian"),
  prior = prior_dims,
  chains = 4,
  iter = 4000,
  warmup = 2000,
  control = list(adapt_delta = 0.99),
  cores = parallel::detectCores(),
  file = "02-environmental.rds"
)

# Model summaries to check fits
summary(fit_soc)  # Social
summary(fit_per)  # Personal
summary(fit_env)  # Environmental

################################################################################
# Plotting results
################################################################################

g_legend <- function(a.gplot) {
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

# Social plot
plot_soc <- plot(conditional_effects(fit_soc, 
                                     effects = "age:country", 
                                     robust = TRUE), plot = FALSE)[[1]] +
  theme_minimal() + 
  labs(title = "Social", x = "Age", y = expression(theta)) + 
  theme(legend.position = "none")
plot_soc$layers[[1]] <- NULL  
plot_soc <- plot_soc + 
  geom_ribbon(aes(ymin = lower__, ymax = upper__, fill = country), 
              alpha = 0.2, color = NA) +
  geom_line(aes(y = estimate__, color = country), linewidth = 1)

# Personal plot
plot_per <- plot(conditional_effects(fit_per, 
                                     effects = "age:country", 
                                     robust = TRUE), plot = FALSE)[[1]] +
  theme_minimal() + 
  labs(title = "Personal", x = "Age", y = expression(theta)) + 
  theme(legend.position = "none") +
  scale_y_continuous(position = "right")
plot_per$layers[[1]] <- NULL
plot_per <- plot_per + 
  geom_ribbon(aes(ymin = lower__, ymax = upper__, fill = country), 
              alpha = 0.2, color = NA) +
  geom_line(aes(y = estimate__, color = country), linewidth = 1)

# Environmental plot
plot_env <- plot(conditional_effects(fit_env, 
                                     effects = "age:country", 
                                     robust = TRUE), plot = FALSE)[[1]] +
  theme_minimal() + 
  labs(title = "Environmental", x = "Age", y = expression(theta)) + 
  theme(legend.position = "none")

plot_env$layers[[1]] <- NULL
plot_env <- plot_env + 
  geom_ribbon(aes(ymin = lower__, ymax = upper__, fill = country), 
              alpha = 0.2, color = NA) +
  geom_line(aes(y = estimate__, color = country), linewidth = 1)

# Extract legend
legend <- g_legend(
  plot(conditional_effects(fit_soc, effects = "age:country", robust = TRUE), 
       plot = FALSE)[[1]] + 
    theme_minimal() +
    labs(color = "Country", fill = "Country")
)

# Combine without header
combined_grid <- grid.arrange(
  plot_soc, plot_per, plot_env, legend,
  ncol = 2, nrow = 2
)

ggsave("Fig4.pdf", combined_grid, width = 9, height = 10)

################################################################################
# End
################################################################################