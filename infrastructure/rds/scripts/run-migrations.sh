#!/usr/bin/env bash
set -e

# Load environment variables
source ./db/.env
echo "PWD: $(pwd)"
# Set absolute path to migrations directory
MIGRATIONS_DIR="$(pwd)/db/migrations"

# Run migrations
dbmate --migrations-dir="$MIGRATIONS_DIR" --env-file=./db/.env up
