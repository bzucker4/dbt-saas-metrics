{% docs saas_activation_definition %}

Share of new users who complete the activation event within N days of signup, plus the median time to activate among those who do.

**Cohort:** calendar month of the first `saas_signup_event` (default `signed_up`).

**Activation:** first `saas_activation_event` (default `activated`) occurs on or after signup and the whole-day difference is less than or equal to `saas_activation_window_days` (default 14).

**activation_rate** = `activated_users / new_users`.

**median_days_to_activate** is the median of `days_to_activate` for users inside the window. Users who activate later are counted in `activated_after_window` and do not enter the median.

{% enddocs %}

{% docs saas_nrr_definition %}

Net revenue retention for accounts that already had MRR at the start of the month.

**NRR** = `(starting_mrr + expansion_mrr - contraction_mrr - churn_mrr) / starting_mrr`.

**GRR** = `(starting_mrr - contraction_mrr - churn_mrr) / starting_mrr`.

New logos and reactivations are excluded. The result is a ratio: `1.0` is 100 percent, `1.15` is 115 percent. `nrr_pct` and `grr_pct` are the same figures times 100. Both are null when starting MRR is 0.

{% enddocs %}

{% docs saas_expansion_definition %}

Month-over-month increase in MRR for an account that already had MRR above zero. The row amount is the delta, not the new total. A first invoice is new MRR. A return from zero is reactivation. Both are excluded here.

{% enddocs %}

{% docs saas_contraction_definition %}

Month-over-month decrease in MRR for an account that remains above zero. Revenue that goes to zero is churn, not contraction.

{% enddocs %}

{% docs saas_churn_definition %}

Accounts whose prior-month MRR was above zero and whose current-month MRR is zero. `churned_mrr` is the prior month's MRR. One row is one churned logo.

{% enddocs %}

{% docs saas_plg_funnel_definition %}

Product-led funnel for the month a person first showed up.

**Stages, in order:** visit, signup (`saas_signup_event`), activation (the activation event at any time after signup), paid (activation, plus positive account MRR or a `saas_paid_event` track).

Each later stage requires the earlier ones, so the counts are monotonic. A signup with no captured page view still counts as a visit. Anonymous page views that never identify remain visitors only.

Time-boxed activation is `saas_activation`, not this model. `signup_to_activation_rate` uses activation at any time.

{% enddocs %}

{% docs saas_waterfall_definition %}

Monthly MRR bridge.

**ending_mrr** = `starting_mrr + new_mrr + expansion_mrr - contraction_mrr - churn_mrr`.

`starting_mrr` is the prior month's ending MRR of accounts that were active. `new_mrr` contains first-time logos and reactivations, because neither was in the starting cohort. `of_which_reactivation_mrr` is the reactivation slice of `new_mrr` and is not added a second time.

Logo counts follow the same bridge: `ending_logos = starting_logos + new_logos + reactivated_logos - churned_logos`.

{% enddocs %}

{% docs saas_health_definition %}

Point-in-time health score from 0 to 100 for each account, as of `saas_as_of_date` or the warehouse clock when that var is unset.

Usage events are track calls in the `saas_health_lookback_days` window (default 30) with an account id. Recency uses the latest track at or before the as-of timestamp, even when it falls outside the volume window.

**Points:** recency up to 40, volume up to 16, payment up to 30 (active MRR 30, past due 12), MRR trend up to 10 (expansion 10, flat or new 6, contraction 3).

**Tiers:** `healthy` at 75 or above, `watch` at 45 to 74, otherwise `at_risk`.

{% enddocs %}
