import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F

import logging

# Configure logging for CloudWatch
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Also log to stdout for AWS Glue CloudWatch
import sys
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

def main():
    """
    AWS Glue ETL Job that:
    1. Reads CSV data from S3
    2. Filters out rows with null values in specified column
    3. Writes transformed data to S3 in Parquet format
    """
    
    try:
        # Get job parameters
        args = getResolvedOptions(sys.argv, [
            'JOB_NAME',
            'SOURCE_BUCKET',
            'SOURCE_PATH',
            'DESTINATION_BUCKET',
            'DESTINATION_PATH',
            'FILTER_COLUMN'
        ])
        
        # Initialize Spark and Glue contexts
        sc = SparkContext()
        glueContext = GlueContext(sc)
        spark = glueContext.spark_session
        job = Job(glueContext)
        job.init(args['JOB_NAME'], args)

        print(f"✅ Starting ETL job: {args['JOB_NAME']}")
        print(f"📋 Job arguments received: {args}")
        logger.info(f"Starting ETL job: {args['JOB_NAME']}")
        logger.info(f"Job arguments received: {args}")

        # Construct S3 paths
        source_path = f"s3://{args['SOURCE_BUCKET']}/{args['SOURCE_PATH']}"
        destination_path = f"s3://{args['DESTINATION_BUCKET']}/{args['DESTINATION_PATH']}"
        filter_column = args['FILTER_COLUMN']
        
        print(f"📂 Source path: {source_path}")
        print(f"📤 Destination path: {destination_path}")
        print(f"🔍 Filter column: {filter_column}")
        logger.info(f"Source path: {source_path}")
        logger.info(f"Destination path: {destination_path}")
        logger.info(f"Filter column: {filter_column}")
        
        # Read CSV data from S3 using DynamicFrame
        logger.info(f"Reading CSV data from {source_path}")
        dynamic_frame = glueContext.create_dynamic_frame.from_options(
            format_options={
                "quoteChar": '"',
                "withHeader": True,
                "separator": ","
            },
            connection_type="s3",
            format="csv",
            connection_options={
                "paths": [source_path],
                "recurse": True
            },
            transformation_ctx="datasource"
        )
        
        # Convert to DataFrame for filtering operations
        df = dynamic_frame.toDF()
        
        logger.info(f"Successfully read data from source. Row count: {df.count()}")
        
        # Debug: Print all column names and their types
        logger.info("Available columns in dataset:")
        for col_name in df.columns:
            logger.info(f"  - '{col_name}'")
        
        # Check if the filter column exists (case-insensitive)
        available_columns = df.columns
        filter_column_lower = filter_column.lower()
        matching_column = None
        
        for col in available_columns:
            if col.lower() == filter_column_lower:
                matching_column = col
                break
        
        if matching_column is None:
            available_columns_str = ", ".join([f"'{col}'" for col in available_columns])
            raise ValueError(f"Filter column '{filter_column}' not found. Available columns: {available_columns_str}")
        
        # Use the actual column name from the dataset
        actual_filter_column = matching_column
        logger.info(f"Using filter column: '{actual_filter_column}'")
        
        # Apply filter to remove null values
        logger.info(f"Filtering out rows with null values in column: {actual_filter_column}")
        filtered_df = df.filter(F.col(actual_filter_column).isNotNull())
        
        # Also filter out empty strings
        filtered_df = filtered_df.filter(
            (F.col(actual_filter_column) != "") & 
            (F.trim(F.col(actual_filter_column)) != "")
        )
        
        logger.info(f"After filtering: Row count: {filtered_df.count()}")
        
        # Convert back to DynamicFrame
        filtered_dynamic_frame = DynamicFrame.fromDF(filtered_df, glueContext, "filtered_data")
        
        # Write to S3 in Parquet format
        logger.info(f"Writing filtered data to {destination_path}")
        glueContext.write_dynamic_frame.from_options(
            frame=filtered_dynamic_frame,
            connection_type="s3",
            format="glueparquet",
            connection_options={
                "path": destination_path
            },
            format_options={
                "compression": "gzip"
            },
            transformation_ctx="datasink"
        )

        logger.info("ETL job completed successfully")
        job.commit()
        
    except Exception as e:
        logger.error(f"ETL job failed with error: {str(e)}")
        raise e

if __name__ == "__main__":
    main()