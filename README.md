# Olist E-Commerce Pipeline: Medallion Architecture in PostgreSQL

A Bronze → Silver → Gold pipeline in plain SQL on the Brazilian Olist dataset (9 tables, ~100K orders), built to answer three retail questions: **revenue performance, customer retention, and delivery performance.**


![Medallion architecture diagram](Projects/Medallion_Diagram.png)

## Architecture

| Layer | Purpose |
|---|---|
| **Bronze** | Raw CSVs loaded as-is, plus load metadata (`_loaded_at`, `_source_file`) |
| **Silver** | Types defined, text standardized, quality flags added, row counts verified against Bronze |
| **Gold** | Order-level master table (`olist_master`) built around the business questions |

## Key decisions

- **Grain discipline:** no transformation changes a table's grain silently.
- **Flag, don't delete:** ambiguous records are flagged (e.g. `delivery_status_flag`: valid / pending / abandoned / corrupted) so nothing is lost.
- **Investigate before deduplicating:** 379 "duplicate" `review_id`s were legitimate many-to-many relationships, not errors.
- **Pre-aggregate in Gold:** items, payments, and reviews are rolled up to order level to prevent join fan-out.
- **Plain SQL over dbt:** keeps the logic fully visible.


## Reproduce

1. Download the [dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
2. Create `bronze`, `silver`, and `gold` schemas in PostgreSQL.
3. Run the scripts in order: `01_bronze` → `02_silver` → `03_gold`.

## Author

**Renzo P. Alporha**, Data Analyst · [LinkedIn](www.linkedin.com/in/renzo-alporha-3b0a25294)
