.PHONY: demo seeds

demo:
	cd integration_tests && dbt deps --profiles-dir . && dbt seed --profiles-dir . && dbt run --profiles-dir . && dbt test --profiles-dir .

seeds:
	python integration_tests/generate_demo_seeds.py
