---
name: dbt-saas-metrics
description: >
  Extend, debug, or configure the dbt_saas_metrics package: Segment and
  Rudderstack sources, activation, NRR, expansion, contraction, churn, the PLG
  funnel, the MRR waterfall, and customer health. Use when editing models,
  macros, vars, source YAML, seeds, or the DuckDB demo in this repository, or
  when a buyer project installs the package and needs vars or source mapping.
---

# dbt_saas_metrics

Commercial dbt package. Models are prefixed `saas_` (marts) or `stg_saas_` / `int_saas_` (upstream). Do not rename them; buyers select on these names.

## Layers

- `models/staging` reads `source('segment', ...)` and `source('billing', 'subscriptions')`. Cast and rename only. No metric math.
- `models/intermediate` holds identity stitching, activation flags, account-month MRR classification, and person-level funnel flags.
- `models/marts` aggregates. `saas_nrr` refs `saas_mrr_waterfall` so retention and the bridge stay aligned. Other marts ref intermediate models, not raw sources.
- `macros` own warehouse differences. Call `saas_datediff`, `saas_date_trunc`, `saas_dateadd`, and `saas_generate_surrogate_key`. Add a new dialect as `warehouse__macro` plus `adapter.dispatch` in the package namespace `dbt_saas_metrics`. Do not put `dateadd` or `generate_series` inline in a model.

## Vars buyers override

Never hardcode schema `segment` as the only location. Sources already use:

- `saas_segment_database`, `saas_segment_schema` (default schema `segment`)
- `saas_billing_database`, `saas_billing_schema` (default to the segment location)
- `saas_identifies_identifier`, `saas_tracks_identifier`, `saas_pages_identifier`, `saas_groups_identifier`, `saas_subscriptions_identifier`
- `saas_column_casing`: `auto` (Snowflake upper, everything else lower), `lower`, or `upper`
- `saas_account_id_column` (default `context_group_id`), `saas_event_column`, `saas_group_id_column`, `saas_group_name_column`, `saas_group_plan_column`
- `saas_signup_event` (`signed_up`), `saas_activation_event` (`activated`), `saas_paid_event` (`subscription_started`)
- `saas_activation_window_days` (14), `saas_health_lookback_days` (30), `saas_as_of_date`, `saas_currency_code`

Read raw columns with `saas_col('column_name')`. Put event-name vars through `saas_event_literal` so quotes cannot break the SQL.

## Metric rules (do not drift)

- Activation rate is time-boxed. The PLG funnel activation stage is "ever activated". Say which one you are changing.
- NRR excludes new logos and reactivations. Waterfall `new_mrr` includes both. `of_which_reactivation_mrr` is a slice of `new_mrr`, not an extra waterfall term.
- Contraction stays above zero MRR. Going to zero is churn.
- Ending MRR = starting + new + expansion - contraction - churn.
- Health is a point-in-time score as of `saas_as_of_date`. Do not use `current_date` inside a model when the var is set; call `saas_as_of_timestamp()`.
- Subscription grain is account-month ending MRR in major units. A missing month after the first snapshot is MRR 0.

## Tests and docs

- Column tests live in the layer YAML. Singular tests in `tests/` must return zero rows on failure.
- When you change a formula, update `models/_saas_docs.md`, `docs/overview.md`, and `seeds/saas_metric_definitions.csv` in the same change.
- Demo expectations live in `integration_tests/tests/assert_demo_expectations.sql`. If you change the seed story, regenerate CSVs with `python integration_tests/generate_demo_seeds.py` and update that test.

## Demo

From `integration_tests`, with `dbt-duckdb` installed:

```bash
dbt deps --profiles-dir .
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
```

Seeds are aliased to `segment.identifies`, `tracks`, `pages`, `groups`, and `subscriptions`. The demo `generate_schema_name` macro does not prefix custom schemas. Do not copy that macro into a buyer's production project.

Package singular tests and schema tests run as part of the demo `dbt test`. Keep them valid for real warehouses, not only the fixture. Put fixture-specific numbers in `integration_tests/tests` only.

## Warehouse notes

Prefer ANSI. `least` is fine. Do not use `QUALIFY`, `ILIKE`, `FILTER`, `TRY_CAST`, or `generate_series` in models. The month spine is a 300-row cross join plus `saas_dateadd`, which stays under Snowflake's recursive CTE limit.

Snowflake Segment columns are uppercase; `saas_col` quotes them. BigQuery `DATE_DIFF` argument order is end then start; that lives only in `bigquery__saas_datediff`.
