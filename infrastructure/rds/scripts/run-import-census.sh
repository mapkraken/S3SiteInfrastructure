#!/bin/bash

# Exit on error
set -e

# Define paths
VENV_PATH="scripts/venv"
PYTHON_SCRIPT="scripts/import_census_block_groups.py"
REQUIREMENTS_FILE="scripts/requirements.txt"
CERTIFI_CA_BUNDLE=$(python3 -m certifi 2>/dev/null || echo "")

# Check if virtualenv exists, create if not
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtualenv at $VENV_PATH..."
    python3 -m venv "$VENV_PATH"
fi

# Activate virtualenv
source "$VENV_PATH/bin/activate"

# Install or update Python dependencies
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing/updating Python dependencies from $REQUIREMENTS_FILE..."
    pip install --upgrade pip
    pip install --upgrade -r "$REQUIREMENTS_FILE"
else
    echo "No requirements.txt found, installing core dependencies..."
    pip install --upgrade pip
    pip install --upgrade requests urllib3 certifi beautifulsoup4 psycopg2-binary python-dotenv
fi

# Install macOS certificates for Python
if [ -f "/Applications/Python 3.13/Install Certificates.command" ]; then
    echo "Installing macOS certificates for Python..."
    /Applications/Python\ 3.13/Install\ Certificates.command
else
    echo "Warning: Install Certificates.command not found."
fi

# Fallback: Set REQUESTS_CA_BUNDLE to certifi's CA bundle if available
if [ -n "$CERTIFI_CA_BUNDLE" ] && [ -f "$CERTIFI_CA_BUNDLE" ]; then
    echo "Setting REQUESTS_CA_BUNDLE to certifi's CA bundle: $CERTIFI_CA_BUNDLE"
    export REQUESTS_CA_BUNDLE="$CERTIFI_CA_BUNDLE"
else
    echo "Warning: certifi CA bundle not found. SSL issues may persist."
fi

# Run the Python script with optional FIPS codes
echo "Running $PYTHON_SCRIPT with FIPS codes: $@"
python "$PYTHON_SCRIPT" --fips "$@"

# Deactivate virtualenv
deactivate

echo "Script execution completed."