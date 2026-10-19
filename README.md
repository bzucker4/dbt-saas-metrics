# dbt SaaS Metrics

**A reusable dbt package for the SaaS metrics teams repeatedly rebuild:** monthly recurring revenue (MRR), revenue retention, expansion and contraction, churn, activation, product-led growth (PLG) funnel conversion, and customer health.

The package turns Segment- or RudderStack-style event data and a monthly account-level billing snapshot into analytics-ready models. A DuckDB demo lets you run the project locally with synthetic data—no warehouse credentials or production data required.

> **Current release:** `v1.0.0` · **Demo:** DuckDB · **Minimum dbt Core:** 1.8+

## Why use it?

SaaS teams often calculate MRR movements, activation, and retention in separate dashboards or one-off SQL. This package provides a consistent starting point with documented metric definitions, configurable source mappings, reusable dbt models, and data-quality tests.

It is designed for analytics engineers and small SaaS data teams that want to adapt a tested baseline instead of starting every metric from scratch. It is not a hosted analytics service or a replacement for your billing system.

## What's included

| Model | Grain | Question it helps answer |
| --- | --- | --- |
| `saas_activation` | Signup month | What share of new users activated within the configured window, and how long did activation take? |
| `saas_nrr` | Month | How did revenue from the starting customer cohort change? |
| `saas_expansion_mrr` | Account-month | Which accounts increased MRR, and by how much? |
| `saas_contraction_mrr` | Account-month | Which accounts reduced MRR without fully churning? |
| `saas_churn` | Account-month | Which accounts went to zero MRR, and how much revenue was lost? |
| `saas_plg_funnel` | First-touch month | How do visitors progress through signup, activation, and paid conversion? |
| `saas_mrr_waterfall` | Month | How do starting MRR, new business, expansion, contraction, and churn reconcile to ending MRR? |
| `saas_customer_health` | Account | Which accounts may need attention based on usage, payment status, and MRR trend? |

Definitions, formulas, assumptions, and the billing data contract are documented in [docs/overview.md](docs/overview.md).

## Try the demo in about 10 minutes

The local integration project uses synthetic Segment-style events and billing data. It is intended to let you inspect the models and tests before connecting your own warehouse.

### Requirements

- Python 3.10+ recommended
- Git
- Internet access for installing Python/dbt dependencies

### Run it

From a clone of this repository:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r integration_tests/requirements.txt

cd integration_tests
dbt deps --profiles-dir .
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
dbt show --select demo_monthly_scorecard --profiles-dir . --limit 12
```

From the repository root, `make demo` runs the demo dependency, seed, run, and test steps.

### What you should see

The synthetic dataset is configured with an as-of date of June 30, 2025. The monthly scorecard should include results like these:

| Example metric | Expected demo result |
| --- | ---: |
| June 2025 ending MRR | $3,800 |
| June expansion MRR | $500 |
| June net revenue retention (NRR) | 1.1515 (about 115.15%) |
| June gross revenue retention (GRR) | 1.00 (100%) |
| January new users | 6 |
| January activated users | 5 |
| January activation rate | 83.33% |
| January median time to activate | 2 days |

These are fixture results from the demo—not a forecast or benchmark for your business. NRR and GRR are ratios, so the dbt output displays them as decimals unless you format them as percentages in a reporting layer.

**Release validation:** the `v1.0.0` clean-install run completed with 120 passing data tests and zero warnings, errors, or skipped tests. The GitHub Actions DuckDB demo workflow also completed successfully. This validates the DuckDB demo; other warehouse adapters still need to be tested against your own schemas and data.

The demo writes its DuckDB database to `integration_tests/target/saas_metrics.duckdb`. The profile is `integration_tests/profiles.yml`; it contains no production credentials.

Optional: generate and serve dbt docs from inside `integration_tests`:

```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

## Install in your dbt project

Use a release tag so your project is pinned to a known version. Replace `YOUR_ORG` with the repository owner or organization that has access to the package.

Add this to your project's `packages.yml`:

```yaml
packages:
  - git: "https://github.com/YOUR_ORG/dbt-saas-metrics.git"
    revision: v1.0.0
```

Then install the dependency:

```bash
dbt deps
```

For a private repository, use a read-only deploy key or fine-grained token. Do not commit credentials to source control. For example:

```yaml
packages:
  - git: "https://{{ env_var('DBT_ENV_SECRET_GIT_CREDENTIAL') }}@github.com/YOUR_ORG/dbt-saas-metrics.git"
    revision: v1.0.0
```

Set `DBT_ENV_SECRET_GIT_CREDENTIAL` in the environment to `x-access-token:YOUR_READ_ONLY_TOKEN`. The `DBT_ENV_SECRET_` prefix tells dbt to treat the value as a secret. Never use a token that has write access if read access is sufficient.

If you received a source archive rather than Git access, unpack it and use a local package path:

```yaml
packages:
  - local: "/path/to/dbt-saas-metrics"
```

This package depends on `dbt-labs/dbt_utils` 1.4.1, which `dbt deps` installs. Minimum supported dbt Core version: 1.8.

To enable the metric dictionary seed in your warehouse:

```yaml
seeds:
  dbt_saas_metrics:
    saas_metric_definitions:
      +enabled: true
```

## Configure your sources

The package uses dbt variables so you can map its expected relations and columns to your warehouse without editing model SQL. Put overrides in your project's `dbt_project.yml`; omit a variable to retain its default.

```yaml
vars:
  saas_segment_database: RAW
  saas_segment_schema: marketing_segment
  saas_billing_database: RAW
  saas_billing_schema: stripe
  saas_subscriptions_identifier: account_mrr_monthly
  saas_signup_event: signed_up
  saas_activation_event: activated
  saas_activation_window_days: 14
  saas_health_lookback_days: 30
  saas_currency_code: USD
  # saas_as_of_date: "2026-10-01"  # omit to use the warehouse clock
```

### Main configuration variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `saas_segment_database` | Target database | Database or BigQuery project containing event tables |
| `saas_segment_schema` | `segment` | Schema or BigQuery dataset containing event tables |
| `saas_billing_database` | Segment database | Database or project containing the billing snapshot |
| `saas_billing_schema` | Segment schema | Schema or dataset containing the billing snapshot |
| `saas_*_identifier` | Source table name | Physical source table or view name |
| `saas_column_casing` | `auto` | Uses uppercase identifiers on Snowflake and lowercase elsewhere by default |
| `saas_account_id_column` | `context_group_id` | Event column containing the account ID |
| `saas_event_column` | `event` | Track event-name column |
| `saas_group_id_column` | `group_id` | Account ID in group records |
| `saas_group_name_column` | `name` | Group name trait |
| `saas_group_plan_column` | `plan` | Group plan trait |
| `saas_signup_event` | `signed_up` | Event that starts the activation cohort |
| `saas_activation_event` | `activated` | Event counted as activation |
| `saas_paid_event` | `subscription_started` | Event counted as paid, alongside a positive MRR snapshot |
| `saas_activation_window_days` | `14` | Days after signup in which activation counts |
| `saas_health_lookback_days` | `30` | Lookback window for usage-event volume |
| `saas_as_of_date` | Warehouse clock | Health snapshot date in `YYYY-MM-DD` format |
| `saas_currency_code` | `USD` | Currency label only; values are not converted |

## Source data contract

| Package source | Default relation | Expected data |
| --- | --- | --- |
| `segment.identifies` | `{database}.{saas_segment_schema}.identifies` | User identity events |
| `segment.tracks` | `...tracks` | Track events, including signup and activation |
| `segment.pages` | `...pages` | Page views for the funnel |
| `segment.groups` | `...groups` | Account/group traits; `group_id` is the account ID |
| `billing.subscriptions` | `{billing_database}.{billing_schema}.subscriptions` | One row per account per month |

If your billing provider exports invoice-level data, create a staging model or view that produces one row per account per month before using the package. The expected billing fields include:

- `account_id`: account identifier matching `group_id` in the event data.
- `month_start`: month represented by the snapshot.
- `mrr`: monthly recurring revenue in major currency units.
- `status`: subscription status such as `active`, `past_due`, or `canceled`.
- `plan_name`, `seats`, and `subscription_id`: optional supporting attributes where available.

A missing month after an account's first snapshot is treated as zero MRR. Confirm that this assumption matches your billing data before using the churn and retention outputs.

Example transformation to a monthly account snapshot (adapt the source field names to your billing system):

```sql
select
    customer_id as account_id,
    date_trunc('month', month) as month_start,
    sum(mrr_amount) as mrr,
    max(status) as status,
    max(plan_name) as plan_name,
    sum(quantity) as seats,
    max(subscription_id) as subscription_id
from your_billing_model
group by 1, 2
```

Then run the package models and tests:

```bash
dbt run --select package:dbt_saas_metrics
dbt test --select package:dbt_saas_metrics
```

Staging and intermediate models are views; marts are tables. Schemas follow your project's `generate_schema_name` macro (usually `{target_schema}_staging`, `{target_schema}_intermediate`, and `{target_schema}_marts`).

## Warehouse compatibility

The package contains adapter-specific SQL for Snowflake, BigQuery, Redshift, and DuckDB. The included automated demo and release validation cover DuckDB; treat the other adapters as integration targets that require verification in your environment.

- **Snowflake:** Segment's native loader commonly uses uppercase columns. With `saas_column_casing: auto`, the package quotes uppercase identifiers. Set `saas_segment_database` to the database containing the Segment data.
- **BigQuery:** `saas_segment_database` is the GCP project and `saas_segment_schema` is the dataset. Date-difference logic uses a BigQuery-specific macro.
- **Redshift:** Set database and schema variables to match your source. Date functions use Redshift-compatible syntax.
- **DuckDB:** Use the included demo project. A sample profile for other targets is in `profiles.yml.example`.

Do not commit passwords or other credentials. Prefer environment variables or a private key path.

## Data quality tests

The package tests cover key uniqueness, accepted customer-health tiers, activation rates between zero and one, NRR bounds when starting MRR is positive, the MRR waterfall identity, and monotonic funnel counts. The demo adds fixture-specific assertions, including June 2025 ending MRR of $3,800 and January activation of five out of six users.

Fixture-specific tests live in `integration_tests` and are not run automatically when you install the package in your own warehouse. Review the metric definitions and adapt tests to your own business rules before relying on the outputs for financial reporting.

## Repository layout

```text
dbt_project.yml
packages.yml
models/               staging, intermediate, marts, sources
macros/                adapter-dispatched date and source helpers
tests/                 package data-quality tests
seeds/                 metric dictionary (disabled until enabled)
docs/overview.md       definitions, formulas, and data contract
integration_tests/     synthetic-data DuckDB demo
```

## License and support

This package is licensed for internal use by the purchasing organization. It is not open source. See [LICENSE](LICENSE) for the terms.

For installation questions or metric-definition support, use the store where you purchased the package. **Do not send warehouse credentials.** See [CHANGELOG.md](CHANGELOG.md) for release history.

An agent working in this repository or in a project that vendors it can follow the [dbt SaaS Metrics skill](.cursor/skills/dbt-saas-metrics/SKILL.md).
