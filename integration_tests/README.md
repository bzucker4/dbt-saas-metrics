# DuckDB demo

This project installs `dbt_saas_metrics` from the parent directory, loads synthetic Segment-shaped seeds into the `segment` schema, and runs the package.

Seeds are aliased onto the source table names the package expects:

| Seed file | Table the package reads |
| --- | --- |
| `raw_identifies.csv` | `segment.identifies` |
| `raw_tracks.csv` | `segment.tracks` |
| `raw_pages.csv` | `segment.pages` |
| `raw_groups.csv` | `segment.groups` |
| `raw_subscriptions.csv` | `segment.subscriptions` |

`macros/generate_schema_name.sql` keeps custom schemas unprefixed so those tables land in `segment`, not `main_segment`. That macro is demo-only. Production projects should keep dbt's default schema prefix.

From this directory:

```bash
dbt deps --profiles-dir .
dbt seed --profiles-dir .
dbt run --profiles-dir .
dbt test --profiles-dir .
dbt show --select demo_monthly_scorecard --profiles-dir . --limit 12
```

Regenerate the CSVs with `python generate_demo_seeds.py` after editing the story in that script.
