#!/bin/bash

# Configuration
TABLE_NAME="$1-MapKrakenContentTable"
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

  echo "Updating item with PK: $pk, SK: $sk in $TABLE_NAME..."
  echo "Site URL: $site_url"
  echo "Repo URLs: $repo_urls"
  echo "Title: $title"
  echo "Description: $description"
  echo "Resources: $resources"
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

# Determine the site_url based on the environment
if [ "$1" == "prd" ]; then
  SITE_URL="https://terriamap.mapkraken.com"
else
  SITE_URL="https://$1-terriamap.mapkraken.com"
fi

# Seed portfolio items
echo "Seeding portfolio data into $TABLE_NAME..."

update_item "PORTFOLIO#1" "#ITEM1" \
  "$SITE_URL" \
  '{"S": "https://github.com/mapkraken/mapkraken-portal"}' \
  "Terriamap" \
  "Containerization and customization of a terriamap application" \
  '{"S": "React"}, {"S": "AWS"}'

echo "Seeding complete!"