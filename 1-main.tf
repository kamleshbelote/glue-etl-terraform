provider "aws" {
  region = var.aws_region
}

# IAM Role for Glue Job
resource "aws_iam_role" "glue_service_role" {
  name = "glue_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policies to the role
resource "aws_iam_role_policy_attachment" "glue_service_role_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}


# S3 access policy for Glue
resource "aws_iam_policy" "glue_s3_access_policy" {
  name        = "glue_s3_access_policy"
  description = "Policy to allow Glue job to access S3 buckets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          aws_s3_bucket.destination_bucket.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:SelectObjectContent"
        ]
        Resource = [
          "${aws_s3_bucket.source_bucket.arn}/*",
          "${aws_s3_bucket.destination_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws-glue/jobs/output*",
          "arn:aws:logs:*:*:log-group:/aws-glue/jobs/error*",
          "arn:aws:logs:*:*:log-group:/aws-glue/jobs/driver/${var.environment}-${var.glue_job_name}*",
          "arn:aws:logs:*:*:log-group:/aws-glue/jobs/metrics/${var.environment}-${var.glue_job_name}*"
        ]
      }
    ]
  })
}

# Attach the S3 access policy to the Glue service role
resource "aws_iam_role_policy_attachment" "glue_s3_access_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_s3_access_policy.arn
}
