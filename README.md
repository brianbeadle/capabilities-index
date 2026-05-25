# Capabilites index code and data

This repository contains the data and code files to replicate the model from the paper "Operationalizing Sen’s capability approach using Bayesian item response theory"

# Files

The table below provides descriptions of the files included in this repository. Please note that due to the size limitations of Github, the model fit files (```.rds```) are not included in the repository. These will have to be fitted by the user if replicating the results of the manuscript. Depending on the computation power of the user's machine, fit times will likely range between several days to a couple weeks. 

## Repository files

- ```01-preprocessing.do```: Preprocessing file for preparing raw survey data for model development
- ```02-modeling.R```: Primary code file with tasks:
    1. Import preprocessed data and recoding
    2. Run factor analyses and all associated tests
    3. Generate summary statistics for manuscript
    4. Run main capabilities index model and generate plots
    5. Run auxiliary regressions (latent trait models) and generate plots
- ```ruwell-final-wide.dta```: Replication data file (see complete description below)

## Plot files

The following posterior predictive check plots are included to evaluate model fit. Please see Bürkner (2017, 2026) for more details.
	
- ```ppc-2d.pdf```: Compares the means and standard deviations between observed and predicted values
- ```ppc-bars.pdf```: Compares the observed and predicted frequency distributions across response categories
- ```ppc-ecdf.pdf```: Provides a comprehensive view of how well the model replicates the overall data distribution

# Data

The data file `ruwell-final-wide.dta` is derived from the RuWell survey, a CAPI household survey conducted in 2024 across rural areas in Albania, Kosovo, Moldova, and Romania. The analytic sample contains 2,039 respondents aged 18 and older who lived in their village for more than six months per year. Full details on sampling and fieldwork are available in (cite).

For replication purposes, `ruwell-final-wide.dta` is used directly as the input file for `02-modeling.R` and no additional preprocessing is required. The Stata preprocessing script `01-preprocessing.do` is provided only for users who wish to replicate the full pipeline from the raw survey data (cite). Running it requires Stata with the `polychoric`, `pcamat`, and `factortest` packages installed.

The dataset contains three broad types of variables. **Control variables** (`age`, `female`, `hhsize`, `kids_LT6`, `mat_leave`, `maritalstat`, employment dummies, and Big Five personality scores) are used as covariates in the auxiliary latent trait regressions. The Big Five traits are each scored as the mean of two items, with reverse-coded items recoded prior to averaging. Two additional variables capture residential intentions: `si` (self-reported probability of staying in the village, 0–100) and `mi` (binary migration intention). **Item response variables** (`y1`–`y38`) capture self-reported assessments across eight life domains: social relations, civic engagement, health, housing, residential environment, natural environment, education, and financial situation. All items are scored on a 1–5 scale; several are reverse-coded so that higher values consistently indicate better outcomes. Three items (`y13`, `y18`, `y23`, `y29`) are composite indices derived from polychoric PCA rather than single survey questions. The capabilities index model uses 12 of these items across three latent dimensions — *Social* (`y1`, `y35`, `y37`, `y38`), *Personal* (`y6`, `y9`, `y12`, `y24`, `y27`), and *Environmental* (`y20`, `y21`, `y22`) — which are bolded in the variable table below.

| Variable | Description |
|----------|-------------|
| `id` | Unique respondent identifier |
| `country` | Country of respondent (1=Albania, 2=Kosovo, 3=Moldova, 4=Romania) |
| `age` | Age in years (continuous) |
| `female` | Gender (0=male, 1=female) |
| `kids_LT6` | Number of children aged 6 years or younger |
| `mat_leave` | Currently on maternal/parental leave (0/1) |
| `maritalstat` | Marital status (1=Married, 2=Partnership, 3=Single, 4=Separated/divorced, 5=Widowed) |
| `hhsize` | Number of persons living permanently in the household |
| `si` | Probability of staying in the village over the next two years (0–100 scale) |
| `student` | Currently enrolled as a student (0/1) |
| `unempl` | Currently unemployed (0/1) |
| `employee` | Employed with a working contract and salary (0/1) |
| `self_empl` | Self-employed (employer or own-account worker) (0/1) |
| `contr_work` | Contributing family worker (0/1) |
| `occ_work` | Occasional worker on demand (0/1) |
| `retired` | Retired (0/1) |
| `big5_extra` | Big Five Extraversion — average of "is reserved" (reversed) and "is outgoing, sociable" (1–5) |
| `big5_agree` | Big Five Agreeableness — average of "is generally trusting" and "tends to find fault with others" (reversed) (1–5) |
| `big5_conc` | Big Five Conscientiousness — average of "tends to be lazy" (reversed) and "does a thorough job" (1–5) |
| `big5_neuro` | Big Five Neuroticism — average of "is relaxed and handles stress well" (reversed) and "gets nervous easily" (1–5) |
| `big5_open` | Big Five Openness — average of "has no interest in art and culture" (reversed) and "has an active imagination" (1–5) |
| **`y1`** | **Sense of belonging and inclusion in the village community (1=Strongly disagree, 5=Strongly agree)** |
| `y2` | Perceived willingness of community members to help each other in times of need (1–5) |
| `y3` | Number of close friends (recoded: 1=none, 2=1–3, 3=4–5, 4=6–10, 5=more than 10) |
| `y4` | Number of community events attended per year (recoded: 1=none, 2=1–2, 3=3–4, 4=5–12, 5=more than 12) |
| `y5` | Likelihood of voting if an election were held next Sunday (1=Definitely not, 5=Definitely yes) |
| **`y6`** | **"I can freely voice my political views" — perceived freedom of speech (1=Strongly disagree, 5=Strongly agree)** |
| `y7` | "The press or media can report independently on various issues" — perceived press freedom (1–5) |
| `y8` | Perception that corruption is prevalent (reversed: higher = less corruption perceived) (1–5) |
| **`y9`** | **Self-rated general physical and mental health (reversed: higher = better health) (1–5)** |
| `y10` | Perceived quality of healthcare services available in the region (1=Very bad, 5=Very good) |
| `y11` | Sufficiency of dwelling size for household needs (1=Not sufficient at all, 5=Very sufficient) |
| **`y12`** | **Current condition of the house or apartment (1=Very bad, 5=Very good)** |
| `y13` | Household amenities index — access to water, electricity, heating, sanitation, internet (PCA-based, deciles 1–10) |
| `y14` | Frequency of worry about safety of home and property (reversed: higher = less worried) (1–5) |
| `y15` | "The roads in my village are of high quality" — perceived local road quality (1=Strongly disagree, 5=Strongly agree) |
| `y16` | Proximity to nearest city center — recoded from travel time in minutes (higher = closer) (1–5) |
| `y17` | "I feel safe in this village" — perceived personal safety (1=Strongly disagree, 5=Strongly agree) |
| `y18` | Village services availability index — supermarket, doctor, pharmacy, schools, etc. (PCA-based, quintiles 1–5) |
| `y19` | "I appreciate the nature and landscape in and around my village" (1=Strongly disagree, 5=Strongly agree) |
| **`y20`** | **"The quality of water bodies in and around my village is very good" (1=Strongly disagree, 5=Strongly agree)** |
| **`y21`** | **"Quality of forests and green cover in and around my village is very good" (1=Strongly disagree, 5=Strongly agree)** |
| **`y22`** | **"Air quality in and around my village is very good" (1=Strongly disagree, 5=Strongly agree)** |
| `y23` | Environmental stressors index — groundwater pollution, heat waves, floods, drought, deforestation, etc. (PCA-based, quintiles 1–5) |
| **`y24`** | **"Everyone can get an education" — perceived equal access to educational resources (1=Strongly disagree, 5=Strongly agree)** |
| `y25` | "The education provided in and around your village is of high quality" (1=Strongly disagree, 5=Strongly agree) |
| `y26` | Educational attainment, harmonised to ISCED 2011 (1=ISCED 1, 2=ISCED 2, 3=ISCED 3, 4=ISCED 4, 5=ISCED 5–8) |
| **`y27`** | **Worry about losing source of income in the next 12 months (reversed: higher = less worried) (1–5)** |
| `y28` | Agreement that the gap between rich and poor in the region is substantial (reversed: higher = disagree) (1–5) |
| `y29` | Household assets index — car, property, land, livestock, machinery, savings, computer, etc. (PCA-based, quintiles 1–5) |
| `y30` | Concern about the economy in general (reversed: higher = less concerned) (1–5) |
| `y31` | Concern about own provision for old age (reversed: higher = less concerned) (1–5) |
| `y32` | Concern about peace in the country (reversed: higher = less concerned) (1–5) |
| `y33` | Concern about crime in the country (reversed: higher = less concerned) (1–5) |
| `y34` | Concern about people leaving the country (reversed: higher = less concerned) (1–5) |
| **`y35`** | **"I am very attached to my village" — place attachment (1=Strongly disagree, 5=Strongly agree)** |
| `y36` | "I feel this village is part of me" — place identity (1=Strongly disagree, 5=Strongly agree) |
| **`y37`** | **"No other place can compare to my village" — place rootedness (1=Strongly disagree, 5=Strongly agree)** |
| **`y38`** | **"This village is the best place for me to live" — place preference (1=Strongly disagree, 5=Strongly agree)** |
| `mi` | Migration intention — would ideally like to go abroad to live or work in the next two years (0/1) |

# References

- Bürkner, P.-C. (2017). *brms: An R Package for Bayesian Multilevel Models Using Stan*. Journal of Statistical Software, 80(1), 1–28. [https://doi.org/10.18637/jss.v080.i01](https://doi.org/10.18637/jss.v080.i01)
- Bürkner, P.-C (2026). *Posterior Predictive Checks for brmsfit Objects*. Retrieved March 18, 2026, from [https://paulbuerkner.com/brms/reference/pp_check.brmsfit.html](https://paulbuerkner.com/brms/reference/pp_check.brmsfit.html)