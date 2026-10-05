-- Fails when a month with starting MRR has NRR outside [0, 10].
-- 0 is total loss of the starting cohort. 1 is 100 percent. 10 is a
-- data-quality ceiling (1000 percent in a single month).

select
    month_start,
    starting_mrr,
    nrr
from {{ ref('saas_nrr') }}
where starting_mrr > 0
    and (
        nrr is null
        or nrr < 0
        or nrr > 10
    )
