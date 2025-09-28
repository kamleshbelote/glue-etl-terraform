#!/bin/bash

# Script to clean up default AWS Glue log groups
# Run this after creating custom log groups

echo "Cleaning up default AWS Glue log groups..."

# List of default log groups to remove
DEFAULT_LOG_GROUPS=(
    "/aws-glue/jobs/error"
    "/aws-glue/jobs/logs-v2"
    "/aws-glue/jobs/output"
)

for log_group in "${DEFAULT_LOG_GROUPS[@]}"; do
    echo "Checking log group: $log_group"
    
    # Check if log group exists
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region us-east-2 --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$log_group"; then
        echo "Deleting default log group: $log_group"
        aws logs delete-log-group --log-group-name "$log_group" --region us-east-2
        echo "✅ Deleted: $log_group"
    else
        echo "ℹ️  Log group not found: $log_group"
    fi
done

echo ""
echo "Remaining Glue log groups:"
aws logs describe-log-groups --region us-east-2 --query 'logGroups[?contains(logGroupName, `glue`) || contains(logGroupName, `aws-glue`)].{Name:logGroupName,RetentionInDays:retentionInDays}' --output table

echo ""
echo "✅ Cleanup complete! Now you have only your custom log groups with proper retention policies."