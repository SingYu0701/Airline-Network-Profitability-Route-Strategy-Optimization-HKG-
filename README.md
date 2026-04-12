# Airline Network Profitability & Route Strategy Optimization (HKG)
**Personal Data Analysis Project, Apr 2026** 
![Made with R](https://img.shields.io/badge/Made%20with-R-276DC3?logo=r&logoColor=white)

## Key Insights

- Profitability is **concentrated in high-demand, high-yield** routes.
- Yield dominates demand in **determining route attractiveness**.
- **Competition and distance** impose **nonlinear penalties** on profitability.
- **Capacity allocation** reinforces **hub-like concentration** patterns.
- **Long-haul** routes are more sensitive to **cost shocks** in scenario analysis.

## 1. Project Overview

This project analyzes the global route network of Hong Kong International Airport (HKG) using OpenFlights aviation data combined with World Bank macroeconomic indicators.

The objective is to move beyond simple route visualization and instead build a **data-driven airline network decision framework** that can support:

- Route profitability evaluation
- Global market segmentation
- Demand and yield estimation
- Strategic network planning
- Risk and scenario sensitivity analysis
  
### Business Motivation

Airline networks are constrained by:

- Demand heterogeneity across countries
- Intense competition on trunk routes
- Strong distance decay effects
- Macroeconomic differences between markets

This project aims to answer:

**Which routes should a hub airport like HKG prioritize for expansion, retention, or reduction?**

## 2. Data Sources
- Aviation Network Data (OpenFlights)
  - Airport nodes (latitude, longitude, country)
  - Route-level connections (origin → destination)
  - Airline-level competition structure

- Macroeconomic Data (World Bank)
  - GDP (total economic size)
  - Population (market scale proxy)
  - GDP per capita (yield proxy / purchasing power)

## 3. Methodology Overview

The analysis follows a structured pipeline:

### 3.1 Data Integration
- Matching destination countries to ISO3 codes
- Merging macroeconomic indicators with route-level data
- Cleaning inconsistent country naming conventions

### 3.2 Feature Engineering

Key constructed variables:

- Demand Proxy
  
    Combines GDP and population:
  - Represents potential passenger base
  
- Yield Proxy
  
    Based on GDP per capita:

  - Captures purchasing power / premium travel potential
- Distance Decay
  - Haversine distance (HKG → destination)
  - Penalizes long-haul inefficiencies
- Competition Intensity
  - Number of airlines operating on each route
    
### 3.3 Profitability Model

A composite **route attractiveness score** is constructed:

$$ProfitScore = (Demand \times GeoWeight \times YieldProxy) \times \frac{1}{1 + Competition} \times \frac{1}{1 + DistancePenalty}$$

**Interpretation:**
- Demand → market size
- Yield → revenue potential
- Competition → pricing pressure
- Distance → operational cost burden

## 4. Top Profitable Routes
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

## 5. Market Structure Clustering

<img width="1774" height="1099" alt="圖片" src="https://github.com/user-attachments/assets/10950709-1c5f-42da-a565-666709ccf1d0" />

K-means clustering is applied to segment destinations into structural market types.

Features used:
- Demand (log GDP + population)
- Competition (log scale)
- Distance (log transformed)
- Yield (GDP per capita)

Resulting Market Segments:
- **Asia Core Markets**
  - High demand, high frequency
  - Strong competition (hub-to-hub routes)
- **Global Premium Long-Haul Markets**
  - High yield, lower frequency
  - Business / premium travel driven
- **Growth Markets**
  - Medium demand
  - Emerging economies with expansion potential
    
**Market size alone does not determine profitability, competition structure is equally important.**

## 6. Strategic Route Prioritization (Best Routes)
<img width="2077" height="1142" alt="圖片" src="https://github.com/user-attachments/assets/6e172f81-ea35-439f-9879-d6dbdfa69654" />

A route prioritization framework was developed by combining demand potential, yield proxy, and competitive intensity to identify **high-value expansion opportunities from HKG**.

The resulting **top-ranked routes (best_routes)** represent destinations with the highest strategic development potential.

Key characteristics of prioritized routes include:

- High underlying market demand (GDP + population scale)
- Strong yield potential (higher income destinations)
- Relatively favorable competition structure
- Balanced distance profile (medium-haul efficiency)

These routes are interpreted as **optimal candidates for network expansion and capacity allocation**, reflecting both profitability potential and strategic network value.


## 7. Strategy Quadrant Map
<img width="1774" height="1099" alt="圖片" src="https://github.com/user-attachments/assets/403b0db1-2c6a-4de1-9ac7-2a2915e9552c" />

Routes are segmented using **demand vs yield** percentiles.

Four Strategic Zones:
- **STAR ROUTES**
  - High demand + high yield
  - Core expansion priority
  - Strong revenue contribution potential
- **NICHE PREMIUM**
  - Low demand but high yield
  - Business travel / premium niche routes
  - Suitable for targeted capacity
- **WEAK ROUTES**
  - Low demand + low yield
  - Likely unprofitable under pressure
  - Candidates for reduction or exit
- **STRATEGIC / SCALE ROUTES**
  - High demand but moderate yield
  - Scale-driven routes (volume-based strategy)
  - Sensitive to competition pressure

## 8. Competition vs Profitability Dynamics

<img width="1265" height="696" alt="圖片" src="https://github.com/user-attachments/assets/13256d69-8d35-42d9-8a27-9aa9bdc121fe" />

This scatter plot shows relationship between:
- ProfitScore
- Competition level

**Some high competition routes still profitable**
**Indicates network effect hubs**

## 9. Robustness Analysis (Scenario Testing)
<img width="1484" height="731" alt="圖片" src="https://github.com/user-attachments/assets/df6a1d29-76aa-44bd-9317-0795e8ba6099" />

To evaluate stability, base and three stress scenarios are simulated:

- **1. Recession Scenario**
  - Reduced demand (−30%)
  - Slight yield compression
- **2. High Fuel Cost Scenario**
  - Distance penalty increases
  - Long-haul routes affected most
- **3. Competition Shock Scenario**
  - Increased airline entry (LCC expansion)
  - Pricing pressure increases

**Robustness Score**

Averaged performance across all scenarios:

- Identifies structurally stable routes
- Helps avoid over-reliance on short-term profitability


## 10. Scenario Sensitivity Heatmap
<img width="2226" height="869" alt="圖片" src="https://github.com/user-attachments/assets/1c0333a0-c6d4-4b08-86b8-1ceed6f01a0d" />


This visualization compares profitability across scenarios for top routes.

Identify fragile vs resilient routes
Understand which routes are:
- **demand-sensitive**
- **cost-sensitive**
- **competition-sensitive**

## 11. Key Findings
- **1. HKG operates as a hybrid hub**
  - Strong Asia-core dominance
  - Significant long-haul premium exposure
- **2. Profitability is multi-factor driven**
  - Demand structure (GDP + population)
  - Competition intensity
  - Yield potential
  - Distance friction
- **3. “High demand” ≠ “high profit”**
  - Many high-volume routes are margin compressed
  - Mid-distance premium routes often outperform
- **4. Strategic expansion targets**
    Best candidates are:
  - High demand markets
  - Low-to-moderate competition
  - Medium haul distance
  - High GDP per capita regions

## 12. Tools & Technologies
- **R (tidyverse)** – data wrangling & modeling
- **geosphere** – geospatial distance calculation
- **countrycode** – country standardization
- **factoextra** – clustering evaluation
- **ggplot2** – visualization
