# =========================
# 0. Libraries
# =========================
library(tidyverse)
library(WDI)
library(geosphere)
library(countrycode)
library(scales)
library(factoextra)
library(ggrepel)
# =========================
# 1. World Bank Data
# =========================
indicators <- c(
  GDP = "NY.GDP.MKTP.CD",
  POP = "SP.POP.TOTL"
)

wb_data <- WDI(
  country = "all",
  indicator = indicators,
  start = 2024, end = 2024
) %>%
  select(iso3c, GDP, POP) %>%
  filter(!is.na(GDP), !is.na(POP)) %>%
  mutate(GDP_per_capita = GDP / POP)

# =========================
# 2. OpenFlights Data
# =========================
airports <- read.csv("airports.dat", header = FALSE)
routes <- read.csv("routes.dat", header = FALSE)

colnames(airports) <- c(
  "AirportID","Name","City","Country","IATA","ICAO",
  "Latitude","Longitude","Altitude","Timezone","DST",
  "TzDatabase","Type","Source"
)

colnames(routes) <- c(
  "Airline","AirlineID",
  "SourceAirport","SourceAirportID",
  "DestAirport","DestAirportID",
  "Codeshare","Stops","Equipment"
)

# =========================
# 3. HKG routes
# =========================
routes_hkg <- routes %>%
  filter(SourceAirport == "HKG") %>%
  left_join(
    airports %>% select(IATA, Country, Latitude, Longitude),
    by = c("DestAirport" = "IATA")
  ) %>%
  rename(
    dest_country = Country,
    dest_lat = Latitude,
    dest_lon = Longitude
  ) %>%
  filter(!is.na(dest_lat), !is.na(dest_lon))

# =========================
# 4. Country fix
# =========================
routes_hkg <- routes_hkg %>%
  mutate(
    dest_country_clean = case_when(
      dest_country == "Burma" ~ "Myanmar",
      dest_country == "Korea, South" ~ "South Korea",
      dest_country == "Korea, North" ~ "North Korea",
      TRUE ~ dest_country
    ),
    iso3c = countrycode(dest_country_clean, "country.name", "iso3c")
  )

# =========================
# 5. Macro features
# =========================
routes_hkg <- routes_hkg %>%
  left_join(wb_data, by = "iso3c") %>%
  mutate(
    GDP = replace_na(GDP, median(GDP, na.rm = TRUE)),
    POP = replace_na(POP, median(POP, na.rm = TRUE)),
    GDP_per_capita = replace_na(GDP_per_capita, median(GDP_per_capita, na.rm = TRUE)),
    
    Demand_base = log(GDP) + log(POP),
    YieldProxy = log(GDP_per_capita)
  )

# =========================
# 6. Distance
# =========================
hkg_coord <- c(113.9185, 22.3080)

routes_hkg <- routes_hkg %>%
  mutate(
    Distance = distHaversine(hkg_coord, cbind(dest_lon, dest_lat)) / 1000
  )

# =========================
# 7. Competition
# =========================
competition_df <- routes %>%
  filter(SourceAirport == "HKG") %>%
  group_by(DestAirport) %>%
  summarise(Competition = n_distinct(Airline), .groups = "drop")

routes_hkg <- routes_hkg %>%
  left_join(competition_df, by = "DestAirport") %>%
  mutate(Competition = replace_na(Competition, 1))

# =========================
# 8. Route aggregation
# =========================
routes_unique <- routes_hkg %>%
  group_by(DestAirport, dest_country, iso3c) %>%
  summarise(
    Demand_base = mean(Demand_base, na.rm = TRUE),
    YieldProxy = mean(YieldProxy, na.rm = TRUE),
    Distance = mean(Distance, na.rm = TRUE),
    Competition = mean(Competition, na.rm = TRUE),
    .groups = "drop"
  )

# =========================
# 9. Frequency weight
# =========================
freq_df <- routes %>%
  filter(SourceAirport == "HKG") %>%
  group_by(DestAirport) %>%
  summarise(freq = n(), .groups = "drop")

routes_unique <- routes_unique %>%
  left_join(freq_df, by = "DestAirport") %>%
  mutate(
    freq = replace_na(freq, 1),
    weight = freq / sum(freq),
    Demand_adj = Demand_base * weight
  )

# =========================
# 10. Market adjustment
# =========================
routes_unique <- routes_unique %>%
  mutate(
    MarketType = case_when(
      iso3c == "CHN" ~ "China",
      iso3c %in% c("USA","JPN","KOR","SGP","GBR","AUS") ~ "Tier1",
      TRUE ~ "Other"
    ),
    GeoWeight = case_when(
      MarketType == "China" ~ 0.75,
      MarketType == "Tier1" ~ 1.2,
      TRUE ~ 1
    )
  )

# =========================
# 11. Feature engineering
# =========================
routes_unique <- routes_unique %>%
  mutate(
    Competition_adj = log1p(Competition),
    Distance_log = log(Distance),
    Distance_norm = as.numeric(scale(Distance_log))
  )

# =========================
# 12. PROFIT SCORE (FIXED - NO OVER-BIAS DIVISION)
# =========================
routes_unique <- routes_unique %>%
  mutate(
    ProfitScore =
      (Demand_adj * GeoWeight * YieldProxy) *
      (1 / (1 + Competition_adj)) *
      (1 / (1 + abs(Distance_norm)))
  ) %>%
  arrange(desc(ProfitScore))

# =========================
# 13. TOP ROUTES
# =========================
top_routes <- routes_unique %>%
  slice_head(n = 15)

print(top_routes)

ggplot(top_routes, aes(x = reorder(DestAirport, ProfitScore), y = ProfitScore)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most Profitable Routes (HKG)",
    x = "Destination Airport",
    y = "Profitability Score"
  )


# =========================
# 15. CLUSTERING 
# =========================
cluster_df <- routes_unique %>%
  transmute(
    demand = scale(log1p(Demand_adj)),
    competition = scale(log1p(Competition)),
    distance = scale(log1p(Distance)),
    yield = scale(YieldProxy)
  )
fviz_nbclust(cluster_df, kmeans, method = "silhouette")
set.seed(123)
km <- kmeans(scale(cluster_df), centers =3, nstart = 25)

routes_unique$Cluster <- as.factor(km$cluster)
routes_unique <- routes_unique %>%
  mutate(
    Cluster = factor(Cluster,
                     levels = c("1", "2", "3"),
                     labels = c(
                       "Asia Core Market (High Volume)",
                       "Global Premium Long-Haul Hub",
                       "Growth Markets"
                     )
    )
  )
# =========================
# 16. CLUSTER PLOT
# =========================
ggplot(routes_unique, aes(log1p(Competition), log1p(Demand_base), color = Cluster)) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title = "Market Structure Clusters (HKG)",
    x = "Market Competition (log scale)",
    y = "Market Demand (log scale)"
  )+
  theme(legend.position = "bottom")
# =========================
# 17. STRATEGY MAP
# =========================
best_routes <- routes_unique %>%
  mutate(
    demand_p = percent_rank(Demand_base),
    yield_p  = percent_rank(YieldProxy),
    comp_p   = percent_rank(-Competition),
    
    score = 0.5 * demand_p +
      0.3 * yield_p +
      0.2 * comp_p
  ) %>%
  arrange(desc(score)) %>%
  slice_head(n = 20)

best_routes
ggplot(best_routes,
       aes(x = reorder(DestAirport, score),
           y = score,
           fill = Cluster)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Priority Routes for Network Expansion (HKG)",
    x = "Destination Airport",
    y = "Development Priority Score"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")


routes_rank <- routes_unique %>%
  arrange(desc(ProfitScore))
top_routes <- routes_rank %>% slice_head(n = 15)
bottom_routes <- routes_rank %>% slice_tail(n = 5)
ggplot(routes_rank,
       aes(x = ProfitScore,
           y = Competition)) +
  geom_point(alpha = 0.6) +
  
  geom_point(data = bottom_routes,
             color = "red",
             size = 3) +
  
  geom_text_repel(
    data = bottom_routes,
    aes(label = DestAirport),
    color = "red",
    size = 3
  ) +
  
  geom_point(data = top_routes,
             color = "blue",
             size = 3) +
  
  geom_text_repel(
    data = top_routes,
    aes(label = DestAirport),
    color = "blue",
    size = 3
  ) +
  labs(
    title = "Competition vs Profit")+
  
  theme_minimal()

routes_q <- routes_rank %>%
  mutate(
    Demand_n = percent_rank(Demand_base),
    Yield_n  = percent_rank(YieldProxy)
  )



d_mid <- median(routes_q$Demand_n)
y_mid <- median(routes_q$Yield_n)

quad_df <- data.frame(
  xmin = c(d_mid, 0, 0, d_mid),
  xmax = c(1, d_mid, d_mid, 1),
  ymin = c(y_mid, y_mid, 0, 0),
  ymax = c(1, 1, y_mid, y_mid),
  zone = c("STAR ROUTES",
           "NICHE PREMIUM",
           "WEAK ROUTES",
           "STRATEGIC / SCALE")
)


ggplot(routes_q,
       aes(x = Demand_n,
           y = Yield_n)) +
  

geom_rect(data = quad_df,
          aes(xmin = xmin, xmax = xmax,
              ymin = ymin, ymax = ymax,
              fill = zone),
          alpha = 0.25,
          inherit.aes = FALSE) +
  
  scale_fill_manual(values = c(
    "STAR ROUTES" = "#66BB6A",        
    "NICHE PREMIUM" = "#42A5F5",      
    "WEAK ROUTES" = "#EF5350",        
    "STRATEGIC / SCALE" = "#FBC02D"   
  ))+
  
  # quadrant lines
  geom_vline(xintercept = d_mid, linetype = "dashed") +
  geom_hline(yintercept = y_mid, linetype = "dashed") +
  
  # points
  geom_point(alpha = 0.7) +
  
  # labels
  geom_text_repel(
    data = routes_q %>%
      filter(Demand_n > 0.9 | Yield_n > 0.9 | Yield_n < 0.1 ),
    aes(label = DestAirport),
    size = 3,
    max.overlaps = 20
  ) +
  
  labs(
    title = "HKG Route Portfolio - 4 Quadrant Strategy Map",
    x = "Demand ",
    y = "Yield ",
    fill = "Strategy Zone"
  ) +
  
  theme_minimal() +
  theme(legend.position = "bottom")


routes_scenario <- routes_unique %>%
  mutate(
    

    Demand_s1 = Demand_adj * 0.7,
    Yield_s1  = YieldProxy * 0.95,
    

    FuelPenalty = Distance_norm * 0.3,
    
 
    Competition_s2 = Competition * 1.3,
    

    
    Profit_Base =
      Demand_adj * YieldProxy *
      (1 / (1 + Competition_adj)) *
      (1 / (1 + abs(Distance_norm))),
    
    Profit_Recession =
      Demand_s1 * Yield_s1 *
      (1 / (1 + log1p(Competition))) *
      (1 / (1 + abs(Distance_norm))),
    
    Profit_HighFuel =
      Demand_adj * YieldProxy *
      (1 / (1 + log1p(Competition))) *
      (1 / (1 + abs(Distance_norm + FuelPenalty))),
    
    Profit_CompetitionShock =
      Demand_adj * YieldProxy *
      (1 / (1 + log1p(Competition_s2))) *
      (1 / (1 + abs(Distance_norm)))
  )
scenario_summary <- routes_scenario %>%
  mutate(
    Robustness =
      (Profit_Recession + Profit_HighFuel + Profit_CompetitionShock) / 3
  ) %>%
  arrange(desc(Robustness)) %>%
  select(
    DestAirport,
    Profit_Base,
    Profit_Recession,
    Profit_HighFuel,
    Profit_CompetitionShock,
    Robustness
  )
scenario_summary %>%
  slice_head(n = 20) %>%
  ggplot(aes(x = reorder(DestAirport, Robustness), y = Robustness)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Route Robustness Under Multiple Scenarios (HKG)",
    x = "Destination Airport",
    y = "Robustness Score"
  ) +
  theme_minimal()
plot_df <- routes_scenario %>%
  select(DestAirport,
         Profit_Base,
         Profit_Recession,
         Profit_HighFuel,
         Profit_CompetitionShock) %>%
  pivot_longer(
    cols = -DestAirport,
    names_to = "Scenario",
    values_to = "Profit"
  )
plot_df$Scenario <- factor(plot_df$Scenario,
                           levels = c("Profit_Base",
                                      "Profit_Recession",
                                      "Profit_HighFuel",
                                      "Profit_CompetitionShock"),
                           
                           labels = c("Base Case",
                                      "Recession",
                                      "High Fuel Cost",
                                      "Competition Shock")
)
ggplot(plot_df %>% 
         filter(DestAirport %in% scenario_summary$DestAirport[1:10]),
       aes(x = Scenario,
           y = DestAirport,
           fill = Profit)) +
  
  geom_tile() +
  
  scale_fill_gradient(
    low = "#FFEBEE",
    high = "#C62828"
  ) +
  
  labs(
    title = "Scenario Sensitivity Heatmap (Top Routes)",
    x = "Scenario",
    y = "Top Destination Routes",
    fill = "Profit Proxy"
  ) +
  
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
