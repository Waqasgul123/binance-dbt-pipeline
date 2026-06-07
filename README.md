# End-to-End Automated Multi-Asset Crypto Data Pipeline

An enterprise-grade, cloud-native data architecture that automatically extracts real-time multi-cryptocurrency pricing data from the live Binance API, ingests it into a cloud data warehouse, transforms nested payloads, and serves a live business intelligence dashboard.

## Architecture Diagram & Medallion Data Flow
[Binance Live API] ──(REST API Array)──> [Azure Data Factory] ──(JSON Drop)──> [Azure Storage Account]
                                                                                      │
                                                                                      ▼ (Bronze Raw Landing)
[Tableau BI Dashboard] <──(ODBC Query)── [dbt Gold Table] <──(Silver View)─── [Snowflake Warehouse Task]

---

##  Medallion Architecture Implementation
* **Bronze Layer (Raw Landing)**: Untouched raw JSON arrays ingested into Snowflake via Azure Data Factory (`crypto.crypto_prices`).
* **Silver Layer (Cleaned & Flattened)**: Structural, data-typed view modeled in dbt to parse the JSON (`stg_crypto_prices`).
* **Gold Layer (Business Ready)**: High-performance physical table with advanced rolling metrics for downstream dashboards (`fct_crypto_prices`).


##  Step-by-Step Technical Implementation

### 1. Ingestion Layer (Azure Data Factory) - Bronze
* **Resource Group**: `rg-binance-analytics` (France Central)
* **Pipeline Name**: `pl_fetch_binance` powered by `adf-binance-engine` (V2)
* **Storage Bucket**: `stbinancedata123` (Private container: `binancejson`)
* **Logic**: Configured a dynamic REST source connection targeting `https://binance.com`. This fetches an open-market JSON array containing over 2,000+ active crypto trading pairs concurrently.

### 2. Warehousing & Automation Layer (Snowflake)
* **Environment**: Database `binance_raw_db`, Schema `crypto`, Compute Warehouse `binance_wh` (XSMALL).
* **Security Protocol**: Connected securely to Azure Blob Storage using a cloud storage integration (`azure_binance_int`) and Microsoft Entra ID Tenant authentication to eliminate hardcoded password risks.
* **Batch Automation**: Established an automated stream engine (`binance_batch_refresh_task`) running on a continuous 5-minute heartbeat schedule. Coupled with `STRIP_OUTER_ARRAY = TRUE`, it automatically unpacks the giant raw arrays into individual database rows.

### 3. Transformation Layer (dbt Cloud) - Silver Staging
* **Sandbox Environment**: Isolated development code configurations inside a dedicated personal schema named `DBT_WGUL`.
* **Staging Logic (`stg_crypto_prices.sql`)**: Authored a custom relational extraction script using Variant JSON string flattening (`raw_payload:symbol::string`, etc.) to map raw nested components into structured, queryable analytics fields (`INGESTED_TIMESTAMP`, `TRADING_PAIR`, `TOKEN_PRICE`).

### 4. Analytical Processing Layer (dbt Cloud) - Gold Mart
* **Analytical Logic (`fct_crypto_prices.sql`)**: Built a downstream business model that materializes as a physical, high-speed table instead of a temporary view to optimize compute costs and query performance.
* **Calculated Metric**: Implemented an advanced SQL Window Function to calculate a **5-tick rolling average price** (`rolling_avg_price`) partitioned by each unique trading pair. This irons out micro-volatility and creates smooth trend lines for the final reporting view.

### 5. Business Intelligence Layer (Tableau)
* **Integration**: Linked Tableau via the native 64-bit Snowflake ODBC driver straight to the dbt-generated Gold analytics table `FCT_CRYPTO_PRICES`.
* **Visualization Layout**: Plots live crypto assets onto a continuous time-series trend line, utilizing independent axis scales to isolate true micro-fluctuations. It features an interactive checklist dropdown sidebar to monitor up to 5 concurrent trading assets simultaneously.


##  Key Automation Features
* **Zero-Maintenance Overhead**: The platform handles incoming currency changes dynamically. When a new asset symbol lands in Snowflake, dbt flattens it automatically without manual schema migrations.
* **Serverless Execution**: The entire infrastructure runs independently in the cloud. You can close all active windows and shut down your local machine; the background workers continue to extract, process, model, and feed your live dashboards completely hands-free.
