# Hong-Kong-HKG-Airline-Network-Optimization-Route-Profitability-Analysis
**Personal Data Analysis Project, Apr 2026** 
![Made with R](https://img.shields.io/badge/Made%20with-R-276DC3?logo=r&logoColor=white)

## 1.Project Overview

**This project analyzes the global route network of Hong Kong International Airport (HKG) using OpenFlights data combined with World Bank macroeconomic indicators.**

The goal is to:

**Identify high-profit air routes**
**Understand market structure and competition**
**Segment destinations using clustering**
**Build a strategic route prioritization model**
**Evaluate robustness under multiple economic scenarios**

## 2.Methodology Overview
Data integration (**OpenFlights + World Bank**)
**Feature engineering** (GDP, population, distance, competition)
Profitability **scoring model**
**K-means clustering** for market segmentation
**Strategic prioritization model**
**Scenario stress testing** (recession, fuel shock, competition shock)

## 3. Top Profitable Routes
<img width="1774" height="1099" alt="圖片" src="https://github.com/user-attachments/assets/945a4e38-ed9d-4fab-926a-ddbbbb6644bd" />

This chart shows the top 15 most profitable routes from HKG based on:
- Demand (GDP + population proxy)
- Yield (GDP per capita)
- Competition adjustment
- Distance penalty

High-profit routes tend to be:
**High GDP countries**
**Moderate competition markets**
**Medium-haul destinations**

## 4. Market Structure Clustering

<img width="1774" height="1099" alt="圖片" src="https://github.com/user-attachments/assets/10950709-1c5f-42da-a565-666709ccf1d0" />

K-means clustering divides destinations into:
- Asia Core Markets
- Global Premium Long-Haul Hub Markets
- Growth Markets

**High demand ≠ high profitability**
**Competition strongly differentiates clusters**

## 5. Strategy Quadrant Map
<img width="1774" height="1099" alt="圖片" src="https://github.com/user-attachments/assets/403b0db1-2c6a-4de1-9ac7-2a2915e9552c" />

Routes are segmented into four strategic zones:
STAR ROUTES
NICHE PREMIUM
WEAK ROUTES
STRATEGIC / SCALE

X-axis: Demand percentile
Y-axis: Yield percentile

**STAR routes = high demand + high yield (core expansion focus)**
**WEAK routes = candidates for reduction or restructuring**

## 6. Profit vs Competition Analysis

<img width="1265" height="696" alt="圖片" src="https://github.com/user-attachments/assets/13256d69-8d35-42d9-8a27-9aa9bdc121fe" />

This scatter plot shows relationship between:
- ProfitScore
- Competition level

**Some high competition routes still profitable**
**Indicates network effect hubs**

## 7. Robustness Analysis (Scenario Testing)
<img width="1484" height="731" alt="圖片" src="https://github.com/user-attachments/assets/df6a1d29-76aa-44bd-9317-0795e8ba6099" />

Scenarios Tested:
- Base
- Recession (Demand shock)
- High fuel cost (distance penalty)
- Competition shock

**Robust routes = stable across all scenarios**
Key for **long-term hub strategy**

## 8. Scenario Sensitivity Heatmap
<img width="1265" height="731" alt="圖片" src="https://github.com/user-attachments/assets/13455a57-a413-4ce8-8a98-7a744e47ff86" />

Compares profitability under:
- Base Case
- Recession
- Fuel shock
- Competition shock

Helps identify risk-sensitive routes
Useful for **strategic hedging decisions**

## Key Model Definition

**Profit Score**

$$ProfitScore = (Demand \times GeoWeight \times YieldProxy) \times \frac{1}{1 + Competition} \times \frac{1}{1 + DistancePenalty}$$

## Data Sources
- OpenFlights: route & airport network data
- World Bank: GDP, population indicators
## Tools Used
- R (tidyverse)
- geosphere (distance calculation)
- countrycode (country mapping)
- factoextra (clustering)
- ggplot2 (visualization)
- 
## Key Takeaways
HKG network is hub-dominant but highly segmented
Profitability is driven more by:
GDP structure
Competition intensity
Distance decay
Best expansion targets are:
High demand + low competition + medium distance routes
