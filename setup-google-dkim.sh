#!/bin/bash
# Complete setup script for Google Workspace DKIM via API
# Handles both Google API and Cloudflare API setup

set -euo pipefail

DOMAIN="${1:-fedlin.com}"
SELECTOR="${2:-google}"

echo "=========================================="
echo "Complete DKIM Setup via APIs"
echo "Domain: ${DOMAIN}"
echo "=========================================="
echo ""

# Check for Python and required libraries
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found"
    exit 1
fi

# Check if Google API libraries are installed
if ! python3 -c "import google.auth, googleapiclient" 2>/dev/null; then
    echo "Google API libraries not installed"
    echo "Installing requirements..."
    pip3 install -q -r requirements.txt || {
        echo "Error: Failed to install Python dependencies"
        echo "Install manually: pip install google-auth google-api-python-client"
        exit 1
    }
fi

# Check for Google credentials
if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    echo "⚠️  GOOGLE_APPLICATION_CREDENTIALS not set"
    echo ""
    echo "You need a Google Service Account JSON file."
    echo "See GOOGLE_API_SETUP.md for setup instructions"
    echo ""
    read -p "Enter path to service account JSON file: " creds_file
    if [ -f "$creds_file" ]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$creds_file"
    else
        echo "Error: File not found: $creds_file"
        exit 1
    fi
fi

# Check for Cloudflare credentials
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ] && [ -z "${CLOUDFLARE_API_KEY:-}" ]; then
    echo "⚠️  Cloudflare API credentials not set"
    echo ""
    echo "You need Cloudflare API credentials to add DNS records"
    echo "See CLOUDFLARE_API_SETUP.md for setup instructions"
    echo ""
    read -p "Enter Cloudflare API Token (or press Enter to skip Cloudflare step): " cf_token
    if [ -n "$cf_token" ]; then
        export CLOUDFLARE_API_TOKEN="$cf_token"
    else
        echo "Skipping Cloudflare DNS update - DKIM key will be displayed for manual addition"
    fi
fi

echo ""
echo "Running Google DKIM script..."
echo ""

# Run the Python script
python3 google_dkim.py

echo ""
echo "Done!"

