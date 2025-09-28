import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job 
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F


import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def main():
    """ 
    AWS Glue ETL Job that:
    1. Reads employee data from a CSV file in S3.
    2. Filters out rows with null values in specified column
    3. Writes the cleaned data back to another S3 bucket in Parquet format.
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

        logger.info(f"Starting ETL job: {args['JOB_NAME']}")

        # Construct S3 paths
        source_s3_path = f"s3://{args['SOURCE_BUCKET']}/{args['SOURCE_PATH']}"
        destination_s3_path = f"s3://{args['DESTINATION_BUCKET']}/{args['DESTINATION_PATH']}"
        filter_column = args['FILTER_COLUMN']

        # Read CSV data from S3 using DynamicFrame
        logger.info(f"Reading data from {source_s3_path}")
        dynamic_frame = glueContext.create_dynamic_frame.from_options(
            format_options ={
                "withHeader": True,
                "separator": ",",
                "quoteChar": '"'
            },
            connection_type = "s3",
            format = "csv",
            connection_options = {
                "paths": [source_s3_path],
                "recurse": True
            },
            transformation_ctx = "dynamic_frame"
        )

        # Convert to DataFrame for filtering operations
        df = dynamic_frame.toDF()
        logger.info(f"Initial data count: {df.count()}")

        # Check if the filter column exists
        if filter_column not in df.columns:
            available_columns = ', '.join(df.columns)
            raise ValueError(f"Column '{filter_column}' does not exist in the data. Available columns: {available_columns}")
        
        # Apply filter to remove rows with null values in the specified column
        filtered_df = df.filter(F.col(filter_column).isNotNull())
        logger.info(f"Filtered data count (non-null '{filter_column}'): {filtered_df.count()}")

        # Also filter out empty strings
        filtered_df = filtered_df.filter(
            (F.col(filter_column) != "") &
            (F.trim(F.col(filter_column)) != "")
        )
        logger.info(f"Filtered data count (non-empty '{filter_column}'): {filtered_df.count()}")

        # Convert back to DynamicFrame
        filtered_dynamic_frame = DynamicFrame.fromDF(filtered_df, glueContext, "filtered_data")

        # Write to S3 in Parquet format
        logger.info(f"Writing cleaned data to {destination_s3_path}")
        glueContext.write_dynamic_frame.from_options(
            frame = filtered_dynamic_frame,
            connection_type = "s3",
            format = "glueparquet",
            connection_options = {
                "path": destination_s3_path
            },
            format_options = {
                "compression": "gzip    "
            },
            transformation_ctx = "datasink"
        )

        logger.info("ETL job completed successfully.")
        job.commit()

    except Exception as e:
        logger.error(f"Error starting ETL job: {e}")
        raise e

if __name__ == "__main__":
    main()