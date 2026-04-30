# infrastructure-data-analysis
An Empirical Analysis of Telecommunications Infrastructure

**Objective:** This repository contains the R data pipeline and statistical analysis for an independent research project examining the efficacy of infrastructure deployment across different political economy models.

### Methodology
To test the theoretical claims of anarcho-capitalism against state-directed economic models, I built an automated data pipeline using **R (dplyr, ggplot2, bigrquery)**. The script synthesizes three distinct global datasets:
1. **World Bank Data:** To calculate the macro-level tax burden.
2. **ITU Global ICT Pricing:** To establish baseline fixed-broadband affordability.
3. **Google M-Lab Telemetry (via BigQuery):** Extracting median download speeds from millions of crowdsourced network diagnostic tests (2020-2024).

### Key Findings
The data challenges the assumption that deregulated private capital maximizes technological innovation. When factoring in total economic burden and calculating the Year-over-Year (YoY) "Innovation Velocity," the free-market benchmark demonstrated significant stagnation compared to the state-directed model.

<img width="3000" height="1800" alt="Innovation_Velocity_Chart" src="https://github.com/user-attachments/assets/b053787a-4b41-4373-b07f-ca362bb1689d" />

### The Code
The full data pipeline, including the SQL query used to extract
 historical data from Google BigQuery, is available in the `Telecom_Analysis.R` script in this repository.
