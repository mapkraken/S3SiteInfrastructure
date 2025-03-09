#!/bin/bash

# Warning: This deletes ALL S3 buckets in your AWS account for the configured region!
echo "WARNING: This will delete ALL S3 buckets and their contents in your AWS account!"
echo "Press Ctrl+C to abort, or Enter to continue..."
read -r

# Get the list of all bucket names
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Check if there are any buckets
if [ -z "$buckets" ]; then
  echo "No buckets found to delete."
  exit 0
fi

# Loop through each bucket
for bucket in $buckets; do
  echo "Processing bucket: $bucket"

  # Check if versioning is enabled
  versioning=$(aws s3api get-bucket-versioning --bucket "$bucket" --query "Status" --output text)
  
  if [ "$versioning" == "Enabled" ]; then
    echo "Bucket $bucket is versioned. Deleting all versions and delete markers..."

    # Delete all object versions
    aws s3api delete-objects --bucket "$bucket" --delete "$(aws s3api list-object-versions --bucket "$bucket" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null

    # Delete all delete markers
    aws s3api delete-objects --bucket "$bucket" --delete "$(aws s3api list-object-versions --bucket "$bucket" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null
  fi

  # Forcefully empty and delete the bucket
  echo "Emptying and deleting bucket: $bucket"
  aws s3 rb s3://"$bucket" --force
done

echo "All buckets deleted."