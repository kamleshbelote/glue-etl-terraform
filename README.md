# AWS Glue ETL Terraform Project

A complete Terraform infrastructure setup for AWS Glue ETL jobs with environment-specific configurations, S3 buckets, IAM roles, and CloudWatch logging.

## 🏗️ Project Structure

```
├── 0-variables.tf          # Variable definitions
├── 1-main.tf              # IAM roles and policies
├── 2-bucket.tf            # S3 buckets and data upload
├── 3-glue.tf              # Glue job and CloudWatch log groups
├── 4-outputs.tf           # Output values and URLs
├── dev/
│   └── dev.tfvars         # Development environment variables
├── qa/
│   └── qa.tfvars          # QA environment variables  
├── prod/
│   └── prod.tfvars        # Production environment variables
├── scripts/
│   ├── glue_employee.py   # Glue ETL Python script
│   └── cleanup-default-logs.sh  # Log cleanup utility
└── data/
    └── sample_employees.csv     # Sample CSV data for testing
```

## 🚀 Features

- **Multi-Environment Support**: Separate configurations for dev, qa, and prod
- **S3 Integration**: Automated bucket creation and data upload
- **IAM Security**: Least-privilege IAM roles and policies
- **CloudWatch Logging**: Organized logging with retention policies
- **ETL Job**: CSV to Parquet conversion with data filtering
- **Infrastructure as Code**: Complete Terraform automation

## 📋 Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Python 3.x (for Glue job)
- Bash shell (for utility scripts)

## 🛠️ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/kamleshbelote/glue-etl-terraform.git
cd glue-etl-terraform
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Deploy to Development Environment
```bash
terraform plan -var-file=dev/dev.tfvars
terraform apply -var-file=dev/dev.tfvars
```

### 4. Run the Glue Job
```bash
aws glue start-job-run --job-name "glue-etl-employee-job" --region us-east-2
```

## 🔧 Configuration

### Environment Variables (dev.tfvars)
```hcl
aws_region = "us-east-2"
source_bucket_name = "kmb-glue-source-bucket"
destination_bucket_name = "kmb-glue-destination-bucket"
glue_job_name = "glue-etl-employee-job"
environment = "dev"
source_path = "data/"
destination_path = "output/"
filter_column = "id"
```

### Key Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-2` |
| `source_bucket_name` | S3 source bucket name | `kmb-glue-source-bucket` |
| `destination_bucket_name` | S3 destination bucket name | `kmb-glue-destination-bucket` |
| `glue_job_name` | Name of the Glue job | `glue-etl-employee-job` |
| `environment` | Environment (dev/qa/prod) | `dev` |
| `filter_column` | Column to filter null values | `id` |
| `log_retention_days` | Log retention period | `14` |
| `error_log_retention_days` | Error log retention period | `30` |

## 📊 Infrastructure Components

### S3 Buckets
- **Source Bucket**: `{environment}-{source_bucket_name}`
- **Destination Bucket**: `{environment}-{destination_bucket_name}`
- **Auto-upload**: Sample data and Glue script

### IAM Resources
- **Glue Service Role**: `glue_service_role`
- **S3 Access Policy**: Read/write permissions for buckets
- **CloudWatch Policy**: Log stream creation and writing

### CloudWatch Log Groups
- **Output Logs**: `/aws-glue/jobs/output` (14 days retention)
- **Error Logs**: `/aws-glue/jobs/error` (30 days retention)
- **Driver Logs**: `/aws-glue/jobs/driver/{environment}-{job_name}` (7 days retention)
- **Metrics Logs**: `/aws-glue/jobs/metrics/{environment}-{job_name}` (14 days retention)

### Glue Job Configuration
- **Version**: Glue 3.0
- **Worker Type**: G.1X
- **Workers**: 2
- **Timeout**: 2880 minutes
- **Language**: Python 3

## 📁 ETL Process

The Glue job performs the following operations:

1. **Read CSV Data**: From S3 source bucket (`data/sample_employees.csv`)
2. **Data Validation**: Check column existence and data types
3. **Filter Null Values**: Remove rows with null/empty values in specified column
4. **Transform Format**: Convert CSV to compressed Parquet
5. **Write Output**: Save processed data to S3 destination bucket

### Sample Data Schema
```csv
id,name,email,age,department,salary,city
1,John Doe,john.doe@example.com,25,Engineering,75000,New York
2,Jane Smith,jane.smith@example.com,30,Marketing,65000,Los Angeles
```

## 🔍 Monitoring & Logging

### CloudWatch Access
After deployment, use the output URLs to access logs:
```bash
terraform output cloudwatch_log_groups_urls
```

### Log Analysis
Search for job arguments and execution details:
```bash
aws logs get-log-events \
  --log-group-name "/aws-glue/jobs/output" \
  --log-stream-name "<job-run-id>" \
  --region us-east-2
```

### Job Monitoring
```bash
# Check job status
aws glue get-job-run \
  --job-name "glue-etl-employee-job" \
  --run-id "<job-run-id>" \
  --region us-east-2

# List recent job runs
aws glue get-job-runs \
  --job-name "glue-etl-employee-job" \
  --region us-east-2
```

## 🌍 Multi-Environment Deployment

### Development
```bash
terraform workspace select dev  # or create if doesn't exist
terraform apply -var-file=dev/dev.tfvars
```

### Production
```bash
terraform workspace select prod
terraform apply -var-file=prod/prod.tfvars
```

### Environment Differences
- **Dev**: Shorter retention, smaller resources
- **QA**: Medium retention, testing configurations  
- **Prod**: Longer retention, production-grade settings

## 🧹 Maintenance

### Clean Up Default Log Groups
```bash
./scripts/cleanup-default-logs.sh
```

### Update Glue Script
```bash
# Modify scripts/glue_employee.py
terraform apply -var-file=dev/dev.tfvars  # Uploads new script
```

### Cost Optimization
- Adjust log retention periods in variables
- Monitor S3 storage costs
- Use Glue job bookmarks for incremental processing

## 🚨 Troubleshooting

### Common Issues

**1. Log Groups Not Appearing**
- Check IAM permissions for CloudWatch
- Verify Glue job configuration
- Look in `/aws-glue/jobs/output` for default logs

**2. S3 Access Denied**
- Verify bucket names in tfvars
- Check IAM role policies
- Ensure bucket regions match

**3. Glue Job Failures**
- Check CloudWatch logs for error details
- Verify CSV file format and location
- Review filter column configuration

### Debug Commands
```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file=dev/dev.tfvars

# View current resources
aws glue get-job --job-name "glue-etl-employee-job"
```

## 🔐 Security Best Practices

- ✅ IAM roles with minimal required permissions
- ✅ S3 bucket encryption at rest
- ✅ CloudWatch log retention policies
- ✅ Environment-specific resource naming
- ✅ No hardcoded credentials in code

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `terraform plan`
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Check AWS Glue documentation
- Review Terraform AWS provider docs

---

**Built with ❤️ using Terraform and AWS Glue**
