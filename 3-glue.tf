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

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.source_bucket.bucket}/scripts/glue_employee.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"       = "python"
    "--SOURCE_BUCKET"      = aws_s3_bucket.source_bucket.bucket
    "--SOURCE_PATH"        = var.source_path
    "--DESTINATION_BUCKET" = aws_s3_bucket.destination_bucket.bucket
    "--DESTINATION_PATH"   = var.destination_path
    "--FILTER_COLUMN"      = var.filter_column
  }

    tags = {
        Environment = var.environment
        Name        = var.glue_job_name
    }

    depends_on = [
        aws_s3_object.glue_script,
        aws_iam_role_policy_attachment.glue_service_role_policy,
        aws_iam_role_policy_attachment.glue_s3_access_policy_attachment
    ]

}