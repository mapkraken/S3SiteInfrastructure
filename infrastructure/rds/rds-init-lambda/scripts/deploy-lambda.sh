#!/bin/bash

# Configuration
LAMBDA_DIR="rds-init-lambda"
ZIP_FILE="rds-init-lambda.zip"
S3_BUCKET="sit-LambdaCodeBucket"
REGION="us-east-1"  # Replace with your AWS region, e.g., us-east-1
echo "lambda_dir: $LAMBDA_DIR"
# Navigate to Lambda directory
cd ".." || { echo "Directory $LAMBDA_DIR not found"; exit 1; }

# Create zip file
zip -r "../$ZIP_FILE" . -x "*.git*" # Excludes .git files, add more exclusions if needed

# Navigate back to parent directory
cd ..

# Upload to S3
aws s3 cp "$ZIP_FILE" "s3://$S3_BUCKET/$ZIP_FILE" --region "$REGION" || { echo "S3 upload failed"; exit 1; }

echo "Successfully packaged and uploaded $ZIP_FILE to s3://$S3_BUCKET/$ZIP_FILE"