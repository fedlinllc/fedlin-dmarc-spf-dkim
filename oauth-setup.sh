#!/bin/bash
# OAuth Setup for Google Workspace Admin API
# Uses gcloud OAuth flow (no service account needed)

set -euo pipefail

echo "=========================================="
echo "Google Workspace OAuth Setup"
echo "=========================================="
echo ""

# Check for gcloud
if ! command -v gcloud >/dev/null 2>&1; then
    echo "Error: gcloud CLI not found"
    echo ""
    echo "Install gcloud CLI:"
    echo "  https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo "Step 1: Authenticate with Google Cloud (OAuth)"
echo "This will open a browser for authentication..."
echo ""
gcloud auth login

echo ""
echo "Step 2: Set up application-default credentials (OAuth)"
echo "This allows scripts to use your OAuth credentials..."
echo "IMPORTANT: Grant Admin SDK API permissions when prompted"
echo ""
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.domain

echo ""
echo "Step 3: Set GCP project (if needed)"
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
echo "Current project: ${CURRENT_PROJECT:-not set}"
echo ""

read -p "Enter Fedlin GCP project ID (or press Enter to keep current): " FEDLIN_PROJECT

if [ -n "$FEDLIN_PROJECT" ]; then
    gcloud config set project "$FEDLIN_PROJECT"
    echo "✓ Project set to: $FEDLIN_PROJECT"
else
    echo "Keeping current project: ${CURRENT_PROJECT}"
fi

echo ""
echo "=========================================="
echo "OAuth Setup Complete!"
echo "=========================================="
echo ""
echo "You can now run:"
echo "  ./google-workspace-dkim.sh fedlin.com"
echo ""
echo "Or set Cloudflare token and run:"
echo "  export CLOUDFLARE_API_TOKEN='your-token'"
echo "  ./google-workspace-dkim.sh fedlin.com"
echo ""

