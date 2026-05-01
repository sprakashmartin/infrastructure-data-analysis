library(tidyverse)
library(janitor)
library(readxl)
library(bigrquery)

# 1. Load Macro Data
wb_data <- read_csv("API_NY.GNP.PCAP.CD_DS2_en_csv_v2_115503.csv", skip = 4) %>% 
  clean_names()

itu_data <- read_excel("ITU_ICTPriceBaskets_2008-2025.xlsx", sheet = "economies_2008-2025") %>% 
  clean_names()

tax_raw <- read_csv("898e791e-0db3-4981-9334-b897a95aca0c_Data.csv", na = "..") %>% 
  clean_names()

infra_raw <- read_csv("fixed-broadband-subscriptions_1777496718795.csv") %>% 
  clean_names()

# 2. Clean Supplemental Data
tax_clean <- tax_raw %>%
  select(country_code, tax_rate_2019 = x2019_yr2019) %>%
  drop_na(tax_rate_2019)

infra_clean <- infra_raw %>%
  filter(data_year == 2024) %>% 
  select(entity_iso, subs_per_100 = data_value)

# 3. Merge Datasets
master_data_advanced <- itu_data %>%
  left_join(wb_data, by = c("iso_code" = "country_code")) %>%
  left_join(tax_clean, by = c("iso_code" = "country_code")) %>%
  left_join(infra_clean, by = c("iso_code" = "entity_iso"))

# 4. Theoretical Calculations
clean_telecom_adv <- master_data_advanced %>%
  filter(str_detect(basket_name, "Fixed-broadband"), unit == "USD") %>%
  mutate(
    monthly_price = as.numeric(x2024.x),
    gni_per_capita = as.numeric(x2024.y),
    tax_rate = as.numeric(tax_rate_2019),
    subs_per_100 = as.numeric(subs_per_100)
  ) %>%
  drop_na(monthly_price, gni_per_capita) %>%
  arrange(iso_code, monthly_price) %>%
  distinct(iso_code, .keep_all = TRUE) %>%
  mutate(
    annual_cost = monthly_price * 12,
    affordability_index = (annual_cost / gni_per_capita) * 100,
    total_burden = affordability_index + tax_rate,
    infra_efficiency = subs_per_100 / affordability_index,
    market_model = case_when(
      iso_code %in% c("CUB", "PRK", "CHN") ~ "State-Owned",
      iso_code %in% c("USA", "GBR", "CHL") ~ "Privatized",
      TRUE ~ "Hybrid" 
    )
  )

# 5. Advanced Summary Table
advanced_summary <- clean_telecom_adv %>%
  group_by(market_model) %>%
  summarize(
    count = n(),
    avg_affordability = mean(affordability_index, na.rm = TRUE),
    avg_total_burden = mean(total_burden, na.rm = TRUE),
    avg_infra_efficiency = mean(infra_efficiency, na.rm = TRUE)
  ) %>%
  arrange(avg_total_burden)

print(advanced_summary)

# 6. Google BigQuery Data Extraction
project_id <- "telecom-thesis-project-2" 

sql_query <- "
  SELECT
    EXTRACT(YEAR FROM date) AS test_year,
    client.Geo.CountryCode AS iso_code,
    APPROX_QUANTILES(a.MeanThroughputMbps, 100)[OFFSET(50)] AS median_speed_mbps
  FROM
    `measurement-lab.ndt.ndt7_union`
  WHERE
    date >= '2020-01-01' AND date <= '2024-12-31'
    AND client.Geo.CountryCode IN ('US', 'GB', 'CL', 'CN')
  GROUP BY
    test_year, iso_code
  ORDER BY
    iso_code, test_year
"

historical_speeds <- bq_project_query(project_id, sql_query) %>%
  bq_table_download()

# 7. Innovation Velocity Calculation
innovation_velocity_data <- historical_speeds %>%
  group_by(iso_code) %>%
  arrange(test_year) %>%
  mutate(
    yoy_growth_pct = (median_speed_mbps - lag(median_speed_mbps)) / lag(median_speed_mbps) * 100
  ) %>%
  filter(test_year == 2024) %>%
  select(iso_code, final_speed = median_speed_mbps, innovation_velocity = yoy_growth_pct)

print(innovation_velocity_data)

# 8. Final Visualization
plot_data <- innovation_velocity_data %>%
  mutate(
    model_label = case_when(
      iso_code == "CN" ~ "State-Owned Benchmark (China)",
      iso_code == "US" ~ "Privatized Model (USA)",
      iso_code == "GB" ~ "Hybrid Model (UK)",
      iso_code == "CL" ~ "Free-Market Benchmark (Chile)"
    )
  )

ggplot(plot_data, aes(x = reorder(model_label, innovation_velocity), y = innovation_velocity, fill = iso_code)) +
  geom_col(alpha = 0.85, width = 0.6) +
  geom_text(aes(label = paste0(round(innovation_velocity, 1), "%")), 
            hjust = -0.2, size = 5, fontface = "bold", color = "black") +
  coord_flip() + 
  scale_fill_manual(values = c("CN" = "#d73027", "US" = "#4575b4", "GB" = "#74add1", "CL" = "#fdae61")) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "grey40", size = 12),
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(face = "bold")
  ) +
  labs(
    title = "The Stagnation of Deregulation: Infrastructure Velocity",
    subtitle = "Year-over-Year Broadband Speed Growth (2020-2024)",
    x = NULL,
    y = "Cumulative Innovation Velocity (%)",
    caption = "Data Source: Measurement Lab (M-Lab) Telemetry via Google Cloud BigQuery"
  ) +
  expand_limits(y = 65) 

ggsave("Innovation_Velocity_Chart.png", width = 10, height = 6, dpi = 300)

library(tidyr)

# 1. Calculate Accessibility Growth (2020 vs 2024)
accessibility_trends <- infra_raw %>%
  filter(data_year %in% c(2020, 2024)) %>%
  select(entity_iso, data_year, data_value) %>%
  # THE FIX: Added 'values_fn = max' to handle the duplicate rows safely
  pivot_wider(names_from = data_year, values_from = data_value, names_prefix = "year_", values_fn = max) %>%
  mutate(
    current_access = as.numeric(year_2024),
    access_growth_pct = ((as.numeric(year_2024) - as.numeric(year_2020)) / as.numeric(year_2020)) * 100
  ) %>%
  drop_na(access_growth_pct)

# 2. Build the "Grand Unified" Index Dataset (CORRECTED)
cumulative_index_data <- clean_telecom_adv %>%
  # 1. Filter using the 3-letter codes from the World Bank data
  filter(iso_code %in% c("USA", "GBR", "CHL", "CHN")) %>% 
  
  # 2. Create a translation key to match Google's 2-letter format
  mutate(google_iso = case_when(
    iso_code == "USA" ~ "US",
    iso_code == "GBR" ~ "GB",
    iso_code == "CHL" ~ "CL",
    iso_code == "CHN" ~ "CN"
  )) %>%
  
  # 3. Join the Google BigQuery Data using our new translation key
  left_join(innovation_velocity_data, by = c("google_iso" = "iso_code")) %>%
  
  # 4. Join the World Bank Accessibility Trends using the standard 3-letter code
  left_join(accessibility_trends, by = c("iso_code" = "entity_iso")) %>%
  
  select(
    iso_code, market_model,
    current_speed = final_speed, speed_growth = innovation_velocity,
    current_access, access_growth = access_growth_pct,
    total_burden
  )

# 3. Scatterplot: Current Status vs. Growth Trajectory
ggplot(cumulative_index_data, aes(x = current_speed, y = speed_growth, fill = iso_code)) +
  # We use a slight 'jitter' or size adjustment to make it look highly academic
  geom_point(shape = 21, size = 7, color = "black", stroke = 1.2, alpha = 0.9) +
  geom_text(aes(label = iso_code), vjust = -1.5, fontface = "bold", size = 5) +
  
  # Add dashed lines representing the mathematical averages to create 4 quadrants
  geom_hline(yintercept = mean(cumulative_index_data$speed_growth), linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = mean(cumulative_index_data$current_speed), linetype = "dashed", color = "gray50") +
  
  scale_fill_manual(values = c("CN" = "#d73027", "US" = "#4575b4", "GB" = "#74add1", "CL" = "#fdae61")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none", panel.grid.minor = element_blank()) +
  labs(
    title = "Infrastructure Dynamics: Stock vs. Flow",
    subtitle = "Current Network Capability vs. Rate of Technological Innovation",
    x = "Stock: Current Absolute Speed (Mbps)",
    y = "Flow: Innovation Velocity / Growth (%)"
  ) +
  # Expand limits so the text labels don't get cut off
  expand_limits(y = max(cumulative_index_data$speed_growth) + 5)

# Save the plot
ggsave("Stock_vs_Flow_Scatterplot.png", width = 9, height = 6, dpi = 300)

# 4. The Telecommunications Cumulative Success Index
composite_index <- cumulative_index_data %>%
  mutate(
    # Normalize variables: (Value - Min) / (Max - Min) * 100
    score_speed = (current_speed - min(current_speed)) / (max(current_speed) - min(current_speed)) * 100,
    score_innovation = (speed_growth - min(speed_growth)) / (max(speed_growth) - min(speed_growth)) * 100,
    score_access = (current_access - min(current_access)) / (max(current_access) - min(current_access)) * 100,
    
    # Invert the Economic Burden: (Max - Value) / (Max - Min) * 100
    score_affordability = (max(total_burden) - total_burden) / (max(total_burden) - min(total_burden)) * 100,
    
    # Calculate the unweighted Cumulative Score
    cumulative_score = (score_speed + score_innovation + score_access + score_affordability) / 4
  ) %>%
  arrange(desc(cumulative_score)) %>%
  # Select only the relevant scores for the final table
  select(iso_code, cumulative_score, score_speed, score_innovation, score_access, score_affordability)

# Print the final index
print(composite_index)

# 8. Clean the Supplemental Data (Now including Density)
tax_clean <- tax_raw %>%
  select(country_code, tax_rate_2019 = x2019_yr2019) %>%
  drop_na(tax_rate_2019)

infra_clean <- infra_raw %>%
  filter(data_year == 2024) %>% 
  select(entity_iso, subs_per_100 = data_value)

# Load and clean the new density file you downloaded
density_raw <- read_csv("API_EN.POP.DNST_DS2_en_csv_v2_1453.csv", skip = 4) %>% 
  clean_names()

density_clean <- density_raw %>%
  # Using 2021 as it is typically the most recent finalized density year in WB data
  select(country_code, population_density = x2021) %>%
  drop_na(population_density)

# 9. The Corrected Multi-Stage Join (Adding Density)
master_data_advanced <- master_data %>%
  left_join(tax_clean, by = c("iso_code" = "country_code")) %>%
  left_join(infra_clean, by = c("iso_code" = "entity_iso")) %>%
  left_join(density_clean, by = c("iso_code" = "country_code"))

# 10. The Final Theoretical Calculations (With Density Control)
clean_telecom_adv <- master_data_advanced %>%
  filter(str_detect(basket_name, "Fixed-broadband")) %>%
  filter(unit == "USD") %>%
  mutate(
    monthly_price = as.numeric(x2024.x),
    gni_per_capita = as.numeric(x2024.y),
    tax_rate = as.numeric(tax_rate_2019),
    subs_per_100 = as.numeric(subs_per_100),
    population_density = as.numeric(population_density)
  ) %>%
  drop_na(monthly_price, gni_per_capita, population_density) %>%
  arrange(iso_code, monthly_price) %>%
  distinct(iso_code, .keep_all = TRUE) %>%
  mutate(
    annual_cost = monthly_price * 12,
    affordability_index = (annual_cost / gni_per_capita) * 100,
    
    total_burden = affordability_index + tax_rate,
    
    # We calculate raw efficiency first
    infra_efficiency = subs_per_100 / affordability_index,
    
    # THE NEW CONTROL: We divide by the log of density to isolate the geographic advantage
    density_adjusted_efficiency = infra_efficiency / log(population_density),
    
    market_model = case_when(
      iso_code %in% c("CUB", "PRK", "CHN") ~ "State-Owned",
      iso_code %in% c("USA", "GBR", "CHL") ~ "Privatized",
      TRUE ~ "Hybrid" 
    )
  )

# 11. Re-build the Cumulative Index Dataset (Now with Density!)
cumulative_index_data <- clean_telecom_adv %>%
  filter(iso_code %in% c("USA", "GBR", "CHL", "CHN")) %>%
  mutate(google_iso = case_when(
    iso_code == "USA" ~ "US",
    iso_code == "GBR" ~ "GB",
    iso_code == "CHL" ~ "CL",
    iso_code == "CHN" ~ "CN"
  )) %>%
  left_join(innovation_velocity_data, by = c("google_iso" = "iso_code")) %>%
  left_join(accessibility_trends, by = c("iso_code" = "entity_iso")) %>%
  select(
    iso_code, market_model,
    current_speed = final_speed, speed_growth = innovation_velocity,
    current_access, access_growth = access_growth_pct,
    total_burden,
    density_adjusted_efficiency # <--- We brought the new control variable in!
  )

# 12. The Z-Score Standardized Success Index
composite_index <- cumulative_index_data %>%
  mutate(
    # Z-Score = (Value - Mean) / Standard Deviation
    z_speed = (current_speed - mean(current_speed)) / sd(current_speed),
    z_innovation = (speed_growth - mean(speed_growth)) / sd(speed_growth),
    z_access = (density_adjusted_efficiency - mean(density_adjusted_efficiency)) / sd(density_adjusted_efficiency),
    
    # For burden, lower is better, so we invert the Z-score by multiplying by -1
    z_affordability = ((total_burden - mean(total_burden)) / sd(total_burden)) * -1,
    
    # Calculate the Cumulative Z-Score
    cumulative_z_score = (z_speed + z_innovation + z_access + z_affordability) / 4
  ) %>%
  arrange(desc(cumulative_z_score)) %>%
  select(iso_code, cumulative_z_score, z_speed, z_innovation, z_access, z_affordability)

print(composite_index)