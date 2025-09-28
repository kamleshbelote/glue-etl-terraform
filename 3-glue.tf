# CloudWatch Log Groups for Glue Job
# Create the default log group that AWS Glue expects, but manage it with retention
resource "aws_cloudwatch_log_group" "glue_job_output_logs" {
  name              = "/aws-glue/jobs/output"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Purpose     = "Glue Job Output Logs - ${var.environment}-${var.glue_job_name}"
    JobName     = var.glue_job_name
    Managed     = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "glue_job_error_logs" {
  name              = "/aws-glue/jobs/error"
  retention_in_days = var.error_log_retention_days

  tags = {
    Environment = var.environment
    Purpose     = "Glue Job Error Logs - ${var.environment}-${var.glue_job_name}"
    JobName     = var.glue_job_name
    Managed     = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "glue_job_driver_logs" {
  name              = "/aws-glue/jobs/driver/${var.environment}-${var.glue_job_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Purpose     = "Glue Job Driver Logs"
    JobName     = var.glue_job_name
  }
}

resource "aws_cloudwatch_log_group" "glue_job_metrics_logs" {
  name              = "/aws-glue/jobs/metrics/${var.environment}-${var.glue_job_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Purpose     = "Glue Job Metrics Logs"
    JobName     = var.glue_job_name
  }
}

# AWS Glue Job
resource "aws_glue_job" "employee_etl_job" {
  name              = var.glue_job_name
  role_arn          = aws_iam_role.glue_service_role.arn
  description       = "ETL job to process employee data from source to destination bucket"
  glue_version      = var.glue_version
  worker_type       = var.glue_worker_type
  number_of_workers = var.number_of_workers
  timeout           = var.glue_timeout
  max_retries       = var.glue_retries

  execution_property {
    max_concurrent_runs = 1
  }

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.source_bucket.bucket}/scripts/glue_employee.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                      = "python"
    "--SOURCE_BUCKET"                     = aws_s3_bucket.source_bucket.bucket
    "--SOURCE_PATH"                       = var.source_path
    "--DESTINATION_BUCKET"                = aws_s3_bucket.destination_bucket.bucket
    "--DESTINATION_PATH"                  = var.destination_path
    "--FILTER_COLUMN"                     = var.filter_column
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-continuous-log-filter"      = "true" 
    "--enable-metrics"                    = "true"
    "--job-bookmark-option"               = "job-bookmark-disable"
  }

  tags = {
    Environment = var.environment
    Name        = var.glue_job_name
  }

  depends_on = [
    aws_s3_object.glue_script,
    aws_iam_role_policy_attachment.glue_service_role_policy,
    aws_iam_role_policy_attachment.glue_s3_access_policy_attachment,
    aws_cloudwatch_log_group.glue_job_output_logs,
    aws_cloudwatch_log_group.glue_job_error_logs,
    aws_cloudwatch_log_group.glue_job_driver_logs,
    aws_cloudwatch_log_group.glue_job_metrics_logs
  ]

}