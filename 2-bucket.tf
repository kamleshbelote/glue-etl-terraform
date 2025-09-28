# S3 Bucket for Source Data
resource "aws_s3_bucket" "source_bucket" {
  bucket        = "${var.environment}-${var.source_bucket_name}"
  force_destroy = true

  tags = {
    Name        = "${var.environment}-${var.source_bucket_name}"
    Environment = var.environment
  }
}

# S3 Bucket for Destination Data
resource "aws_s3_bucket" "destination_bucket" {
  bucket        = "${var.environment}-${var.destination_bucket_name}"
  force_destroy = true
  tags = {
    Name        = "${var.environment}-${var.destination_bucket_name}"
    Environment = var.environment
  }
}

# Upload Glue ETL Script to Source Bucket
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.source_bucket.id
  key    = "scripts/glue_employee.py"
  source = "${path.module}/scripts/glue_employee.py"
  etag   = filemd5("${path.module}/scripts/glue_employee.py")

  tags = {
    Purpose     = "Glue ETL Script - Employee Data"
    Environment = var.environment
  }

  depends_on = [aws_s3_bucket.source_bucket]
}


# Optional: Upload sample data for testing
resource "aws_s3_object" "sample_data" {
  bucket = aws_s3_bucket.source_bucket.id
  key    = "data/sample_employees.csv"
  source = "${path.module}/data/sample_employees.csv"
  etag   = filemd5("${path.module}/data/sample_employees.csv")

  tags = {
    Purpose     = "Sample Employee Data for ETL Testing"
    Environment = var.environment
  }

  depends_on = [aws_s3_bucket.source_bucket]
}