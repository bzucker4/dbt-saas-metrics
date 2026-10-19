-- A pre-signup activation must not mask the first activation after signup.
-- The fixture signs up on July 10, has an earlier activation on July 1,
-- and a valid activation on July 12. The model should report two days to activate.

select user_id, signup_at, activated_at, days_to_activate
from {{ ref('int_saas_user_activation') }}
where user_id = 'user_edge'
  and (
      activated_at <> cast('2025-07-12 09:00:00' as timestamp)
      or days_to_activate <> 2
      or not activated_ever
      or not activated_within_window
  )

union all

select user_id, signup_at, activated_at, days_to_activate
from {{ ref('int_saas_user_activation') }}
where days_to_activate < 0
