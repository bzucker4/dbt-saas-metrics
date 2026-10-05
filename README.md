# dbt_saas_metrics

Pre-built dbt models for B2B SaaS: activation, net revenue retention, expansion and contraction, churn, a product-led funnel, an MRR waterfall, and a customer health score. The models expect Segment or Rudderstack event tables plus a monthly billing snapshot, and they run on Snowflake, BigQuery, Redshift, and DuckDB.

You configure database, schema, table, and column names with vars. The default schema is `segment`. That is a default, not a requirement.

## What you get

| Model | Grain | What it answers |
| --- | --- | --- |
| `saas_activation` | Signup month | What share of new users activated within N days, and how long it took |
| `saas_nrr` | Month | Net and gross revenue retention of the starting cohort |
| `saas_expansion_mrr` | Account-month | Which customers increased MRR, and by how much |
| `saas_contraction_mrr` | Account-month | Which customers decreased MRR without leaving |
| `saas_churn` | Account-month | Which customers went to zero, and the MRR lost |
| `saas_plg_funnel` | First-touch month | Visit → signup → activation → paid conversion |
| `saas_mrr_waterfall` | Month | Starting, new, expansion, contraction, churn, ending |
| `saas_customer_health` | Account | 0–100 score from usage, payment, and MRR trend |

Definitions, formulas, and the billing contract are in [docs/overview.md](docs/overview.md).

## 10-minute quick start (DuckDB)

You do not need Snowflake credentials to see the marts. The `integration_tests` project loads synthetic Segment data and runs the package.

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

From the repo root, `make demo` runs deps, seed, run, and test.

`dbt show` should include a June 2025 row with ending MRR **3800**, expansion **500**, and NRR about **1.15** (115%). January activation is **5 of 6** users, median **2** days. `dbt test` must finish with no failures.

Optional docs site, still inside `integration_tests`:

```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

The demo profile is `integration_tests/profiles.yml`. It writes `integration_tests/target/saas_metrics.duckdb` and contains no secrets. `saas_as_of_date` is `2025-06-30` so the health score treats June usage as current.

## Install in your project

Pin a release tag. Replace the org and repo with the URL from your purchase.

```yaml
# packages.yml
packages:
  - git: "https://github.com/YOUR_ORG/dbt_saas_metrics.git"
    revision: v1.0.0
```

Private repository, without putting the token in git history:

```yaml
packages:
  - git: "https://{{ env_var('DBT_ENV_SECRET_GIT_CREDENTIAL') }}@github.com/YOUR_ORG/dbt_saas_metrics.git"
    revision: v1.0.0
```

Set `DBT_ENV_SECRET_GIT_CREDENTIAL` to `x-access-token:YOUR_READ_ONLY_TOKEN` (the `DBT_ENV_SECRET_` prefix keeps it out of dbt logs). A deploy key or read-only fine-grained token is enough. Do not use a personal token that can push.

If you received a zip instead of git access, unpack it and depend on the local path:

```yaml
packages:
  - local: "/path/to/dbt_saas_metrics"
```

Then `dbt deps`. This package depends on `dbt-labs/dbt_utils` 1.4.1, which `dbt deps` installs for you. Requires dbt Core 1.8 or newer.

Enable the metric dictionary seed if you want it in the warehouse:

```yaml
seeds:
  dbt_saas_metrics:
    saas_metric_definitions:
      +enabled: true
```

## Required vars

Put overrides in your `dbt_project.yml`. Omit a var to keep the default.

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
  # saas_as_of_date: "2026-10-01"   # omit to use the warehouse clock
```

| Var | Default | Role |
| --- | --- | --- |
| `saas_segment_database` | target database | Database or BigQuery project of the event tables |
| `saas_segment_schema` | `segment` | Schema or BigQuery dataset of the event tables |
| `saas_billing_database` | segment database | Where the MRR snapshot lives |
| `saas_billing_schema` | segment schema | Schema of the MRR snapshot |
| `saas_*_identifier` | table name in the source | Physical table or view name |
| `saas_column_casing` | `auto` | `upper` on Snowflake, `lower` elsewhere. Set explicitly if your loader differs |
| `saas_account_id_column` | `context_group_id` | Event column that holds the account id |
| `saas_event_column` | `event` | Track event-name column |
| `saas_group_id_column` | `group_id` | Group account id column |
| `saas_group_name_column` | `name` | Group name trait |
| `saas_group_plan_column` | `plan` | Group plan trait |
| `saas_signup_event` | `signed_up` | Track event that starts the activation cohort |
| `saas_activation_event` | `activated` | Track event that counts as activation |
| `saas_paid_event` | `subscription_started` | Track event that also counts as paid, alongside any positive MRR snapshot |
| `saas_activation_window_days` | `14` | Days after signup that still count as activated |
| `saas_health_lookback_days` | `30` | Window for health event volume |
| `saas_as_of_date` | warehouse clock | Health snapshot date (`YYYY-MM-DD`) |
| `saas_currency_code` | `USD` | Label only. Amounts are not converted |

## Source mapping

| Package source | Default relation | Your warehouse |
| --- | --- | --- |
| `segment.identifies` | `{database}.{saas_segment_schema}.identifies` | Segment or Rudderstack identifies |
| `segment.tracks` | `...tracks` | tracks |
| `segment.pages` | `...pages` | pages |
| `segment.groups` | `...groups` | groups. `group_id` is the account |
| `billing.subscriptions` | `{billing database}.{billing schema}.subscriptions` | One row per account per month |

Build the billing relation as a view if Stripe is invoice-shaped. `mrr` is monthly recurring revenue in major units. `account_id` must match `group_id`. `status` should be `active`, `past_due`, or `canceled`. A missing month after the first snapshot is treated as zero MRR.

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

Then run:

```bash
dbt run --select package:dbt_saas_metrics
dbt test --select package:dbt_saas_metrics
```

Staging and intermediate models are views. Marts are tables. Schemas follow your project's `generate_schema_name` (usually `{target_schema}_staging`, `{target_schema}_intermediate`, `{target_schema}_marts`).

## Warehouse notes

**Snowflake.** Segment's native loader uses uppercase columns. The package quotes uppercase identifiers when `saas_column_casing` is `auto`. Set `saas_segment_database` to the Segment database. The month spine covers 25 years without a recursive CTE.

**BigQuery.** `saas_segment_database` is the GCP project and `saas_segment_schema` is the dataset. Date differences go through `date_diff`, which is implemented in the BigQuery macro, not in the models.

**Redshift.** Set database and schema vars the same way. `datediff` and `dateadd` use Redshift's unquoted date parts. `date_trunc` keeps the date part as a string, which is what Redshift requires.

**DuckDB.** Use the demo project above. A copy-paste profile for other targets is in `profiles.yml.example`. Do not commit passwords. Prefer `env_var()` or a private key path.

## Tests

`dbt test` checks primary keys, accepted health tiers, activation rates between 0 and 1, NRR between 0 and 10 whenever starting MRR is positive, the waterfall identity, and a monotonic funnel. The demo adds fixture checks (June ending MRR 3800, January activation 5/6). Those fixture checks live only in `integration_tests` and do not run in your warehouse.

## Project layout

```
dbt_project.yml
packages.yml
models/          staging, intermediate, marts, sources
macros/          adapter.dispatch date helpers and source helpers
tests/           singular tests that ship with the package
seeds/           metric dictionary (disabled until you enable it)
docs/overview.md
integration_tests/   DuckDB demo
```

## License and support

This package is sold for internal use by the buying organization. It is not open source. See [LICENSE](LICENSE). All rights reserved.

Questions about install or metric definitions go through the store where you purchased it. Do not send warehouse credentials. [CHANGELOG](CHANGELOG.md) lists what shipped in 1.0.0.

An agent working in this repo, or in a project that vendors it, can follow [.cursor/skills/dbt-saas-metrics/SKILL.md](.cursor/skills/dbt-saas-metrics/SKILL.md).
