#!/bin/bash

# Configuration
TABLE_NAME="sit-MapKrakenContentTable"
REGION="us-east-1"

# Function to delete an item from DynamoDB
delete_item() {
  local pk="$1"
  local sk="$2"

  aws dynamodb delete-item \
    --table-name "$TABLE_NAME" \
    --key '{
      "PK": {"S": "'"$pk"'"},
      "SK": {"S": "'"$sk"'"}
    }' \
    --region "$REGION" \
    --return-consumed-capacity TOTAL
}

# Delete specific portfolio items
echo "Removing portfolio items from $TABLE_NAME..."

delete_item "PORTFOLIO#1" "#ITEM2"
echo "Deleted item with SK #ITEM2"

delete_item "PORTFOLIO#1" "#ITEM3"
echo "Deleted item with SK #ITEM3"

echo "Deletion complete!"