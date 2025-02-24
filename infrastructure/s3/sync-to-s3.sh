#!/bin/bash
LOCAL_DIR="./sync/mapkraken-labs"
BUCKET_NAME="s3-${STAGE}-${NAMESPACE}${NAMESPACE_SHORT}"
REGION="us-east-1"
if [ -z "$STAGE" ] || [ -z "$NAMESPACE" ] || [ -z "$NAMESPACE_SHORT" ]; then
  echo "Error: STAGE, NAMESPACE, and NAMESPACE_SHORT must be set."
  exit 1
fi
if [ ! -d "$LOCAL_DIR" ]; then
  echo "Error: Local directory $LOCAL_DIR does not exist."
  exit 1
fi
echo "Syncing $LOCAL_DIR to s3://$BUCKET_NAME..."
aws s3 sync "$LOCAL_DIR" "s3://$BUCKET_NAME/" --region "$REGION" --delete
if [ $? -eq 0 ]; then
  echo "Sync completed successfully."
else
  echo "Error: Sync failed."
  exit 1
fi