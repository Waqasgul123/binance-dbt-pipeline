# End-to-End Automated Multi-Asset Crypto Data Pipeline

An enterprise-grade, cloud-native data architecture that automatically extracts real-time multi-cryptocurrency pricing data from the live Binance API, ingests it into a cloud data warehouse, transforms nested payloads, and serves a live business intelligence dashboard.

##  Architecture Diagram & Data Flow
[Binance Live API] ──(REST API Array)──> [Azure Data Factory] ──(JSON Drop)──> [Azure Storage Account]
                                                                                      │
[Tableau BI Dashboard] <──(ODBC Query)── [dbt Cloud View] <──(Flatten View)── [Snowflake Warehouse Task]


##  Step-by-Step Technical Implementation

### 1. Ingestion Layer (Azure Data Factory)
* **Resource Group**: `rg-binance-analytics` (France Central)
* **Pipeline Name**: `pl_fetch_binance` powered by `adf-binance-engine` (V2)
* **Storage Bucket**: `stbinancedata123` (Private container: `binancejson`)
* **Logic**: Configured a dynamic REST source connection targeting `https://binance.com`. This fetches an open-market JSON array containing over 2,000+ active crypto trading pairs concurrently.

### 2. Warehousing & Automation Layer (Snowflake)
* **Environment**: Database `binance_raw_db`, Schema `crypto`, Compute Warehouse `binance_wh` (XSMALL).
* **Security Protocol**: Connected securely to Azure Blob Storage using a cloud storage integration (`azure_binance_int`) and Microsoft Entra ID Tenant authentication to eliminate hardcoded password risks.
* **Batch Automation**: Established an automated stream engine (`binance_batch_refresh_task`) running on a continuous 5-minute heartbeat schedule. Coupled with `STRIP_OUTER_ARRAY = TRUE`, it automatically unpacks the giant raw arrays into individual database rows.

### 3. Transformation Layer (dbt Cloud)
* **Sandbox Environment**: Isolated development code configurations inside a dedicated personal schema named `DBT_WGUL`.
* **Staging Logic**: Authored a custom relational extraction script using Variant JSON string flattening (`raw_payload:symbol::string`, etc.) to map raw nested components into structured, queryable analytics fields (`INGESTED_TIMESTAMP`, `TRADING_PAIR`, `TOKEN_PRICE`).
* **Deployment**: Merged into the stable production `main` branch to lock automation loops into cloud execution history.

### 4. Business Intelligence Layer (Tableau)
* **Integration**: Linked Tableau via the native 64-bit Snowflake ODBC driver straight to the dbt-generated `STG_CRYPTO_PRICES` dataset view.
* **Visualization Layout**: Plots live crypto assets onto a continuous time-series trend line, utilizing independent axis scales to isolate true micro-fluctuations. It features an interactive checklist dropdown sidebar to monitor up to 5 concurrent trading assets simultaneously.

##  Key Automation Features
* **Zero-Maintenance Overhead**: The platform handles incoming currency changes dynamically. When a new asset symbol lands in Snowflake, dbt flattens it automatically without manual schema migrations.
* **Serverless Execution**: The entire infrastructure runs independently in the cloud. You can close all active windows and shut down your local machine; the background workers continue to extract, process, model, and feed your live dashboards completely hands-free.
