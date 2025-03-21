#!/bin/bash

# Configuration
TABLE_NAME="sit-MapKrakenContentTable"
REGION="us-east-1"

# Function to add or update an item in DynamoDB
update_item() {
  local pk="$1"
  local sk="$2"
  local site_url="$3"
  local repo_urls="$4"
  local title="$5"
  local description="$6"
  local resources="$7"

  aws dynamodb update-item \
    --table-name "$TABLE_NAME" \
    --key '{
      "PK": {"S": "'"$pk"'"},
      "SK": {"S": "'"$sk"'"}
    }' \
    --update-expression "SET site_url = :site_url, repo_urls = :repo_urls, title = :title, description = :description, resources = :resources" \
    --expression-attribute-values '{
      ":site_url": {"S": "'"$site_url"'"},
      ":repo_urls": {"L": ['"$repo_urls"']},
      ":title": {"S": "'"$title"'"},
      ":description": {"S": "'"$description"'"},
      ":resources": {"L": ['"$resources"']}
    }' \
    --region "$REGION" \
    --return-consumed-capacity TOTAL
}

# Seed portfolio items
echo "Seeding portfolio data into $TABLE_NAME..."

update_item "PORTFOLIO#1" "#ITEM1" \
  "https://sit-terriamap.mapkraken.com" \
  '{"S": "https://github.com/mapkraken/mapkraken-portal"}' \
  "Terriamap" \
  "Containerization and customization of a terriamap application" \
  '{"S": "React"}, {"S": "AWS"}'

echo "Seeding complete!"