variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "source_bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
  default     = "kmb-glue-source-bucket"
}

variable "destination_bucket_name" {
  description = "The name of the destination S3 bucket to create"
  type        = string
  default     = "kmb-glue-destination-bucket"
}

variable "glue_job_name" {
  description = "The name of the Glue job"
  type        = string
  default     = "glue-etl-employee-job"
}

variable "environment" {
  description = "The environment for the resources"
  type        = string
  default     = "dev"

}

variable "glue_worker_type" {
  description = "The type of worker for the Glue job"
  type        = string
  default     = "Standard"
}

variable "number_of_workers" {
  description = "The number of workers for the Glue job"
  type        = number
  default     = 1
}

variable "glue_timeout" {
  description = "The timeout for the Glue job in minutes"
  type        = number
  default     = 10
}

variable "glue_retries" {
  description = "The number of retries for the Glue job"
  type        = number
  default     = 0
}

variable "glue_version" {
  description = "The version of Glue to use"
  type        = string
  default     = "3.0"
}

variable "source_path" {
  description = "The source path in the S3 bucket"
  type        = string
  default     = "input/"
}

variable "destination_path" {
  description = "The destination path in the S3 bucket"
  type        = string
  default     = "output/"
}

variable "filter_column" {
  description = "Column name to filter out null values"
  type        = string
  default     = "id"
}