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

### Stock vs. Flow & Cumulative Success Index
To evaluate long-term systemic viability, the analysis compares current infrastructure capability (Stock) against the rate of technological innovation (Flow). 

<img width="2700" height="1800" alt="Stock_vs_Flow_Scatterplot" src="https://github.com/user-attachments/assets/ff87979f-7e2a-4a7e-9158-5fd81fb02ff5" />

By normalizing all four variables—Access Density, Quality of Service, Innovation Velocity, and Tax-Adjusted Affordability—into a 0-100 scale, we can calculate a **Cumulative Success Index**. 

### Density-Adjusted Cumulative Success Index
To evaluate long-term systemic viability, the model normalizes four variables into a 0-100 scale: Access Density, Quality of Service (Stock), Innovation Velocity (Flow), and Tax-Adjusted Affordability. 

Crucially, the Access metric controls for **Omitted Variable Bias** by dividing raw infrastructure efficiency by the logarithm of national population density. This penalizes geographically dense nations (like the UK) that fail to capitalize on their "easy" terrain, and rewards sparse nations for overcoming geographic hurdles.

The final output mathematically demonstrates that extreme deregulation (Chile) results in the lowest overall systemic success, even when controlling for challenging geography. 

| Rank | Model | ISO | Cumulative Score | Speed (Stock) | Innovation (Flow) | Density-Adjusted Access | True Affordability |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Privatized (Subsidized) | USA | **58.9** | 100 | 41.6 | 14.3 | 79.8 |
| **2** | State-Owned Benchmark | CHN | **50.0** | 0 | 100 | 100 | 0 |
| **3** | Hybrid Model | GBR | **43.5** | 55.4 | 17.4 | 1.11 | 100 |
| **4** | Free-Market Benchmark | CHL | **26.8** | 22.2 | 0 | 0 | 84.9 |
