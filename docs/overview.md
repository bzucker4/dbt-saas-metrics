# Metric definitions

`dbt_saas_metrics` turns Segment or Rudderstack event tables, plus a monthly billing snapshot, into the SaaS models finance and growth teams ask for. Amounts are in one currency. The package labels that currency with `saas_currency_code` and does not convert currencies.

## Source contract

Event tables default to the `segment` schema in the target database. Override `saas_segment_database`, `saas_segment_schema`, and the identifier vars. Rudderstack's warehouse schema matches this contract.

| Source | Default table | Required columns |
| --- | --- | --- |
| `segment.identifies` | `identifies` | `id`, `anonymous_id`, `user_id`, `timestamp`, `email`, `context_group_id` |
| `segment.tracks` | `tracks` | `id`, `anonymous_id`, `user_id`, `event`, `timestamp`, `context_group_id` |
| `segment.pages` | `pages` | `id`, `anonymous_id`, `user_id`, `timestamp`, `url`, `path`, `context_group_id` |
| `segment.groups` | `groups` | `id`, `group_id`, `user_id`, `timestamp`, `name`, `plan` |
| `billing.subscriptions` | `subscriptions` | `subscription_id`, `account_id`, `month_start`, `mrr`, `status`, `plan_name`, `seats` |

`account_id` on events comes from `context_group_id` unless you set `saas_account_id_column`. Group traits `name` and `plan` can be renamed with `saas_group_name_column` and `saas_group_plan_column`.

Billing defaults to the same schema as events. Point `saas_billing_database` and `saas_billing_schema` at a Stripe model when billing lives elsewhere. `account_id` must equal Segment `group_id`.

Subscription grain is one row per account per month. `mrr` is ending recurring revenue in major units (dollars, not cents). `status` is `active`, `past_due`, or `canceled`. You can omit a churned month. After an account's first snapshot, a missing month is treated as MRR 0 and becomes churn in the first empty month.

Column casing is automatic: uppercase on Snowflake, lowercase elsewhere. Set `saas_column_casing` to `lower` or `upper` when your loader does something else.

## Activation

Model: `saas_activation`. Grain: signup month.

A user is new when they fire `saas_signup_event` (default `signed_up`). They are activated when they fire `saas_activation_event` (default `activated`) within `saas_activation_window_days` (default 14). Days are whole calendar days.

`activation_rate` = activated users / new users.

`median_days_to_activate` is the median among users who activated inside the window. Later activations are counted in `activated_after_window` and are excluded from the median.

## Net revenue retention

Model: `saas_nrr`. Grain: calendar month.

Starting MRR is the prior month's ending MRR of accounts that were above zero. Expansion, contraction, and churn are measured only on that cohort.

NRR = (starting MRR + expansion - contraction - churn) / starting MRR.

GRR = (starting MRR - contraction - churn) / starting MRR.

New logos and reactivations are excluded. The ratio is `1.0` at 100 percent. `nrr_pct` is the ratio times 100. NRR is null when starting MRR is 0.

A singular test fails when starting MRR is positive and NRR is outside 0 to 10. That ceiling is a data-quality guard, not a business target. Edit `tests/assert_nrr_bounds.sql` if a real month should exceed it.

## Expansion, contraction, churn

`saas_expansion_mrr` is the positive delta for an account that already had MRR and still has more. The first invoice is not expansion.

`saas_contraction_mrr` is the delta when MRR falls but stays above zero.

`saas_churn` is one row per account that goes from positive MRR to zero. `churned_mrr` is the prior month's MRR. Sum `churned_logo` for a logo count.

## MRR waterfall

Model: `saas_mrr_waterfall`. Grain: calendar month.

ending MRR = starting MRR + new MRR + expansion - contraction - churn.

`new_mrr` includes first-time logos and reactivations, because neither was in starting MRR. `of_which_reactivation_mrr` is the reactivation slice of `new_mrr`. Do not add it again.

Logo counts use the same bridge.

## PLG funnel

Model: `saas_plg_funnel`. Grain: month of first page view, or signup month when no page was captured.

Stages are sequential:

1. Visit. A signup with no page view still counts as a visit.
2. Signup (`saas_signup_event`).
3. Activation. The activation event at any time after signup.
4. Paid. Activation, plus either an account that has ever had MRR above zero or a `saas_paid_event` track (default `subscription_started`).

Anonymous visitors who never identify stay at the visit stage. The time-boxed activation rate is `saas_activation`, not the funnel's signup-to-activation rate.

## Customer health

Model: `saas_customer_health`. Grain: one account, evaluated as of `saas_as_of_date` or `current_timestamp`.

The score is capped at 100.

| Component | Rule | Max |
| --- | --- | --- |
| Recency | <=7 days 40, <=14 days 30, <=30 days 20, <=60 days 10 | 40 |
| Volume | >=8 events 16, >=3 events 12, >=1 event 6, inside `saas_health_lookback_days` | 16 |
| Payment | active MRR 30, past due with MRR 12 | 30 |
| Trend | expansion 10, flat / new / reactivation 6, contraction 3 | 10 |

`healthy` is 75 or above. `watch` is 45 to 74. Anything lower is `at_risk`.

Set `saas_as_of_date` when you are replaying history. The demo sets it to `2025-06-30` so June usage is recent.

## How the layers fit

Staging renames source columns and drops rows with no primary timestamp. Intermediate models stitch identities, classify MRR movements, and flag funnel stages. Marts aggregate those models. Marts do not read raw sources.

`saas_nrr` is computed from `saas_mrr_waterfall`, so the retention ratio and the bridge cannot drift apart.
