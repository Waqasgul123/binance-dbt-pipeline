{{ config(materialized='table') }}

with silver_staging as (
    select * from {{ ref('stg_crypto_prices') }}
)

select
    ingested_timestamp,
    trading_pair,
    token_price,
    price_window_minutes,
    -- Gold Layer Metric: 5-tick rolling average to smooth market volatility
    avg(token_price) over (
        partition by trading_pair 
        order by ingested_timestamp 
        rows between 5 preceding and current row
    ) as rolling_avg_price
from silver_staging
order by ingested_timestamp desc
