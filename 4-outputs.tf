# Outputs for CloudWatch Log Groups
output "glue_job_output_log_group" {
  description = "CloudWatch Log Group for Glue job output logs"
  value       = aws_cloudwatch_log_group.glue_job_output_logs.name
}

output "glue_job_error_log_group" {
  description = "CloudWatch Log Group for Glue job error logs"
  value       = aws_cloudwatch_log_group.glue_job_error_logs.name
}

output "glue_job_driver_log_group" {
  description = "CloudWatch Log Group for Glue job driver logs"
  value       = aws_cloudwatch_log_group.glue_job_driver_logs.name
}

output "glue_job_metrics_log_group" {
  description = "CloudWatch Log Group for Glue job metrics logs"
  value       = aws_cloudwatch_log_group.glue_job_metrics_logs.name
}

output "glue_job_name" {
  description = "Name of the Glue job"
  value       = aws_glue_job.employee_etl_job.name
}

output "cloudwatch_log_groups_urls" {
  description = "URLs to access CloudWatch log groups"
  value = {
    output_logs = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.glue_job_output_logs.name, "/", "$252F")}"
    error_logs  = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.glue_job_error_logs.name, "/", "$252F")}"
    driver_logs = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.glue_job_driver_logs.name, "/", "$252F")}"
    metrics_logs = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.glue_job_metrics_logs.name, "/", "$252F")}"
  }
}