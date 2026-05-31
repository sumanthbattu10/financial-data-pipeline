# Financial Data Analytics Pipeline

End-to-end ETL pipeline using Python, Snowflake, dbt, Airflow, and AWS — 
built to process financial transaction data and deliver analytics dashboards.

## Tech Stack
- **Python** — data ingestion, transformation, automation
- **Snowflake** — cloud data warehouse
- **dbt** — data transformation and modeling (star schema)
- **Apache Airflow** — pipeline orchestration and SLA monitoring
- **AWS** — S3 (data lake), Redshift, Glue, Athena
- **Great Expectations** — automated data quality validation
- **Tableau / Power BI** — executive dashboards

## Features
- Automated ETL/ELT pipeline ingesting from 5+ upstream data sources
- Star schema dimensional data models with dbt tests and lineage
- Data quality framework with automated validation and alerting
- SLA monitoring with zero data quality escapes over 3 months
- Self-service analytics reducing ad hoc requests by 45%

## Pipeline Architecture
Raw Data (S3) → Python Ingestion → Snowflake Staging → 
dbt Transformations → Analytics Layer → Tableau Dashboard

## Results
- Reduced data latency from 6 hours to under 30 minutes
- Improved pipeline throughput by 35%
- Achieved 91% precision on anomaly detection
