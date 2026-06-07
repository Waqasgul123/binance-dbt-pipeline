{{ config(materialized='view') }}

with raw_data as (
    select * from {{ source('binance_source', 'crypto_prices') }}
)

select
    loaded_at as ingested_timestamp,
    raw_payload:symbol::string as trading_pair,
    raw_payload:price::numeric(16, 4) as token_price,
    raw_payload:mins::int as price_window_minutes
from raw_data
