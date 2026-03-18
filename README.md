# Capabilites index code and data

This repository contains the data and code files to replicate the model from the paper "Operationalizing Sen’s capability approach using Bayesian item response theory"

# Files

Please note that due to the size limitations of Github, the model fit (.RDS) files are not included in the repository. These will have to be fitted by the user if replicating the results of the manuscript. Depending on the computation power of the user's machine, fit times will likely range between several days to a couple weeks. 

## Code files

- ```01-...```: Preprocessing file for preparing raw survey data for model development
- ```02-final.R```: Primary code file with tasks:
    1. Import preprocessed data and recoding
    2. Run factor analyses and all associated tests
    3. Generate summary statistics for manuscript
    4. Run main capabilities index model and generate plots
    5. Run auxiliary regressions (latent trait models) and generate plots

## Plot files

The following posterior predictive check plots are included to evaluate model fit. Please see Bürkner (2017, 2026) for more details.
	
- ```ppc-2d.pdf```: Compares the means and standard deviations between observed and predicted values
- ```ppc-bars.pdf```: Compares the observed and predicted frequency distributions across response categories
- ```ppc-ecdf.pdf```: Provides a comprehensive view of how well the model replicates the overall data distribution

# References

Bürkner, P.-C. (2017). *brms: An R Package for Bayesian Multilevel Models Using Stan*. Journal of Statistical Software, 80(1), 1–28. [https://doi.org/10.18637/jss.v080.i01](https://doi.org/10.18637/jss.v080.i01)
Bürkner, P.-C (2026). *Posterior Predictive Checks for brmsfit Objects*. Retrieved March 18, 2026, from [https://paulbuerkner.com/brms/reference/pp_check.brmsfit.html](https://paulbuerkner.com/brms/reference/pp_check.brmsfit.html)