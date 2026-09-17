# Olist E-Commerce Customer Analytics

An end-to-end e-commerce analytics project using SQL, DuckDB, Python, and Power BI to analyze customer behavior, revenue concentration, retention, delivery experience, and customer satisfaction.

## Project Overview

This project analyzes the Brazilian Olist e-commerce dataset to answer key business questions around:

- Customer retention and repeat purchasing
- Revenue and customer value distribution
- RFM customer segmentation
- High-value customer behavior
- Delivery performance and customer satisfaction
- Revenue concentration
- Customer experience across value tiers
- Business segments based on customer value and repeat behavior

The project follows a complete analytics workflow from raw data exploration and SQL analysis to customer-level feature engineering and an interactive Power BI dashboard.

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Python | Data understanding and analysis |
| Pandas | Data manipulation |
| DuckDB | SQL analytics and analytical database |
| SQL | Data cleaning, transformation and business analysis |
| Power BI | Interactive dashboard and visualization |
| Jupyter Notebook | Exploratory analysis |
| Git & GitHub | Version control and project sharing |

---

## Dataset

The project uses the **Brazilian E-Commerce Public Dataset by Olist**.

The original dataset contains information about:

- Customers
- Orders
- Order items
- Payments
- Reviews
- Products
- Sellers
- Geolocation
- Product category translations

Raw datasets and the DuckDB database are intentionally excluded from this repository using `.gitignore`.

---

# Project Workflow

```text
Raw Olist Dataset
       ↓
Python Data Understanding
       ↓
DuckDB Database
       ↓
SQL Data Quality & Relationship Checks
       ↓
Analytics Views
       ↓
Business Analysis
       ↓
Customer Feature Engineering
       ↓
RFM Analysis
       ↓
Customer Value & Retention Analysis
       ↓
Dashboard Dataset Creation
       ↓
Power BI Dashboard