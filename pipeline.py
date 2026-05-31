"""
Financial Data Pipeline
Author: Sumanth Battu
Description: ETL pipeline for financial transaction data
"""

import pandas as pd
import numpy as np
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FinancialDataPipeline:
    """
    End-to-end ETL pipeline for financial transaction data.
    Ingests from multiple sources, transforms, and loads to Snowflake.
    """

    def __init__(self, config: dict):
        self.config = config
        self.pipeline_run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        logger.info(f"Pipeline initialized: {self.pipeline_run_id}")

    def extract(self, source: str) -> pd.DataFrame:
        """Extract raw financial transaction data from source"""
        logger.info(f"Extracting data from: {source}")
        # Simulated transaction data
        df = pd.DataFrame({
            'transaction_id': range(1000),
            'customer_id': np.random.randint(1, 500, 1000),
            'amount': np.random.uniform(10, 10000, 1000),
            'transaction_date': pd.date_range('2024-01-01', periods=1000, freq='H'),
            'category': np.random.choice(['purchase', 'refund', 'transfer'], 1000),
            'status': np.random.choice(['completed', 'pending', 'failed'], 1000)
        })
        logger.info(f"Extracted {len(df)} records")
        return df

    def validate(self, df: pd.DataFrame) -> pd.DataFrame:
        """Data quality validation using Great Expectations style checks"""
        logger.info("Running data quality validation...")
        initial_count = len(df)

        # Check for nulls
        df = df.dropna(subset=['transaction_id', 'customer_id', 'amount'])

        # Check for negative amounts
        df = df[df['amount'] > 0]

        # Check for valid categories
        valid_categories = ['purchase', 'refund', 'transfer']
        df = df[df['category'].isin(valid_categories)]

        removed = initial_count - len(df)
        if removed > 0:
            logger.warning(f"Removed {removed} invalid records")

        logger.info(f"Validation passed: {len(df)} clean records")
        return df

    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        """Transform and enrich transaction data"""
        logger.info("Applying transformations...")

        # Feature engineering
        df['transaction_month'] = df['transaction_date'].dt.month
        df['transaction_year'] = df['transaction_date'].dt.year
        df['transaction_hour'] = df['transaction_date'].dt.hour
        df['is_high_value'] = (df['amount'] > 1000).astype(int)
        df['amount_bucket'] = pd.cut(
            df['amount'],
            bins=[0, 100, 500, 1000, float('inf')],
            labels=['low', 'medium', 'high', 'very_high']
        )

        # Customer aggregations
        customer_stats = df.groupby('customer_id').agg(
            total_spend=('amount', 'sum'),
            avg_transaction=('amount', 'mean'),
            transaction_count=('transaction_id', 'count')
        ).reset_index()

        df = df.merge(customer_stats, on='customer_id', how='left')
        logger.info("Transformations complete")
        return df

    def load(self, df: pd.DataFrame, target: str):
        """Load transformed data to Snowflake/Redshift"""
        logger.info(f"Loading {len(df)} records to {target}")
        # In production: use snowflake-connector-python or boto3
        # df.to_sql(target, connection, if_exists='append', index=False)
        logger.info("Load complete")
        return True

    def run(self):
        """Execute full pipeline"""
        logger.info("Starting Financial Data Pipeline...")
        try:
            df = self.extract("s3://financial-data/transactions/")
            df = self.validate(df)
            df = self.transform(df)
            self.load(df, "snowflake.analytics.transactions")
            logger.info(f"Pipeline completed successfully: {len(df)} records processed")
            return {"status": "success", "records": len(df)}
        except Exception as e:
            logger.error(f"Pipeline failed: {str(e)}")
            return {"status": "failed", "error": str(e)}


if __name__ == "__main__":
    config = {
        "source": "s3://financial-data/",
        "target": "snowflake.analytics",
        "batch_size": 10000
    }
    pipeline = FinancialDataPipeline(config)
    result = pipeline.run()
    print(f"Result: {result}")
