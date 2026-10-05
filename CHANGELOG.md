# Changelog

## 1.0.0 - 2026-10-05

First commercial release of `dbt_saas_metrics`.

- Staging models for Segment and Rudderstack `identifies`, `tracks`, `pages`, and `groups`, plus monthly subscription snapshots.
- Intermediate models for identity stitching, activation, account-month MRR, and the PLG funnel.
- Marts: `saas_activation`, `saas_nrr`, `saas_expansion_mrr`, `saas_contraction_mrr`, `saas_churn`, `saas_plg_funnel`, `saas_mrr_waterfall`, `saas_customer_health`.
- Cross-warehouse macros via `adapter.dispatch` for date diff, date trunc, date add, and surrogate keys.
- Source database, schema, table, and column names are vars. Nothing is hardcoded to a single `segment` schema.
- Singular tests for NRR bounds, waterfall balance, and a monotonic PLG funnel.
- DuckDB integration project with synthetic Segment-style seeds.
