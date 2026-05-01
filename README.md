# infrastructure-data-analysis
An Empirical Analysis of Telecommunications Infrastructure

**Objective:** This repository contains the R data pipeline and statistical analysis for an independent research project examining the efficacy of infrastructure deployment across different political economy models.

### Methodology
To test the theoretical claims of anarcho-capitalism against state-directed economic models, I built an automated data pipeline using **R (dplyr, ggplot2, bigrquery)**. The script synthesizes three distinct global datasets:
1. **World Bank Data:** To calculate the macro-level tax burden.
2. **ITU Global ICT Pricing:** To establish baseline fixed-broadband affordability.
3. **Google M-Lab Telemetry (via BigQuery):** Extracting median download speeds from millions of crowdsourced network diagnostic tests (2020-2024).

### Benchmark Definitions & Regulatory Nuance
While this model utilizes categorical benchmarks ("Privatized" vs. "State-Owned") for macro-statistical analysis, the underlying regulatory realities are highly nuanced, demonstrating the limits of ideological absolutes in infrastructure deployment:
* **The "Free-Market" Mandates (Chile):** While highly privatized, the Chilean state aggressively intervenes to correct market failures. Private 5G spectrum auctions were legally tethered to "Social Mandates," forcing operators to wire unprofitable rural localities. Furthermore, Chile imposes strict net neutrality and number portability laws to prevent monopoly abuse. 
* **The "State-Owned" Retail Tier (China):** While the physical infrastructure (fiber, towers) is an absolute monopoly owned by state-controlled entities (SASAC), the state permits private Mobile Virtual Network Operators (MVNOs) to lease bandwidth and operate at the retail and consumer-facing margins.

### Key Findings
The data challenges the assumption that deregulated private capital maximizes technological innovation. When factoring in total economic burden and calculating the Year-over-Year (YoY) "Innovation Velocity," the free-market benchmark demonstrated significant stagnation compared to the state-directed model.

<img width="3000" height="1800" alt="Innovation_Velocity_Chart" src="https://github.com/user-attachments/assets/b053787a-4b41-4373-b07f-ca362bb1689d" />

### The Code
The full data pipeline, including the SQL query used to extract historical data from Google BigQuery, is available in the `Telecom_Analysis.R` script in this repository.

### Stock vs. Flow & Cumulative Success Index
To evaluate long-term systemic viability, the analysis compares current infrastructure capability (Stock) against the rate of technological innovation (Flow). 

<img width="2700" height="1800" alt="Stock_vs_Flow_Scatterplot" src="https://github.com/user-attachments/assets/ff87979f-7e2a-4a7e-9158-5fd81fb02ff5" />

### Density-Adjusted Cumulative Success Index (Z-Score Standardization)
To rigorously evaluate long-term systemic viability and eliminate the "artificial zero" effect of min-max scaling, the model standardizes four core variables into Z-scores (measuring standard deviations from the baseline mean): Access Density, Quality of Service (Stock), Innovation Velocity (Flow), and Tax-Adjusted Affordability. 

Crucially, the Access metric controls for **Omitted Variable Bias** by dividing raw infrastructure efficiency by the logarithm of national population density. This penalizes geographically dense nations (like the UK) that fail to capitalize on their "easy" terrain, and rewards sparse nations for overcoming geographic hurdles.

The final output mathematically demonstrates that extreme deregulation (Chile) results in the lowest overall systemic success, dropping nearly half a standard deviation below the mean, even when controlling for challenging geography. 

| Rank | Model | ISO | Cumulative Z-Score | Speed (Z) | Innovation (Z) | Density-Adjusted Access (Z) | True Affordability (Z) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Privatized (Subsidized) | USA | **0.330** | 1.280 | 0.043 | -0.304 | 0.303 |
| **2** | State-Owned Benchmark | CHN | **0.093** | -1.020 | 1.380 | 1.490 | -1.470 |
| **3** | Hybrid Model | GBR | **-0.022** | 0.253 | -0.513 | -0.579 | 0.752 |
| **4** | Free-Market Benchmark | CHL | **-0.402** | -0.510 | -0.911 | -0.603 | 0.417 |

### Methodological Stress Test: The Mobile Leapfrog Effect
A major critique of fixed-broadband indices is the "Mobile Leapfrog Effect"—the theory that developing or highly deregulated nations bypass physical cable infrastructure entirely in favor of wireless networks. 

To test this, a secondary parallel pipeline was constructed using World Bank Mobile Cellular Subscriptions (IT.CEL.SETS.P2) and ITU Data-Only Mobile Broadband pricing. 

**Findings:** The leapfrog effect was empirically confirmed. While the free-market benchmark (Chile) failed in fixed-line density (-0.603 Z-Score), it surged in mobile density (+0.752 Z-Score), vastly outperforming the USA (-1.22 Z-Score). Ultimately, when measuring wireless infrastructure, the systemic gap between privatized and state-directed models effectively disappears, compressing the scores into a near-statistical tie. This suggests mobile technology acts as a structural equalizer across varying political economies. 

| Rank | Model | ISO | Mobile Cumulative Z-Score | Mobile Access Density (Z) | Mobile Affordability (Z) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Privatized (Subsidized) | USA | **0.0889** | -1.220 | 0.254 |
| **2** | Hybrid Model | GBR | **0.0176** | -0.413 | 0.744 |
| **3** | Free-Market Benchmark | CHL | **-0.0492** | 0.752 | 0.472 |
| **4** | State-Owned Benchmark | CHN | **-0.0572** | 0.881 | -1.470 |

*Note: The Cumulative Mobile Z-Score also factors in the baseline Network Speed (Stock) and Innovation Velocity (Flow) metrics utilized in the fixed-line index.*
