#!/bin/bash
# Setup script to configure GCP project for Fedlin

set -euo pipefail

echo "=========================================="
echo "Fedlin GCP Project Configuration"
echo "=========================================="
echo ""

# Check current project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
echo "Current GCP project: ${CURRENT_PROJECT:-not set}"
echo ""

# List available projects
echo "Available projects:"
gcloud projects list --format="table(projectId,name)" 2>&1 | head -20 || {
    echo "Note: Need to authenticate to list projects"
    echo "Run: gcloud auth login"
}

echo ""
read -p "Enter Fedlin GCP project ID (or press Enter to keep current): " FEDLIN_PROJECT

if [ -n "$FEDLIN_PROJECT" ]; then
    echo ""
    echo "Setting GCP project to: $FEDLIN_PROJECT"
    gcloud config set project "$FEDLIN_PROJECT" 2>&1 || {
        echo "Error: Could not set project. You may need to authenticate."
        echo "Run: gcloud auth login"
        exit 1
    }
    echo "✓ Project set to: $FEDLIN_PROJECT"
else
    echo "Keeping current project: ${CURRENT_PROJECT}"
    FEDLIN_PROJECT="$CURRENT_PROJECT"
fi

echo ""
echo "Setting up application-default credentials..."
gcloud auth application-default login 2>&1 || {
    echo "Note: Application-default credentials setup requires interactive login"
    echo "Run manually: gcloud auth application-default login"
}

echo ""
echo "=========================================="
echo "Configuration Complete"
echo "=========================================="
echo ""
echo "To use in scripts, set:"
echo "  export GCP_PROJECT=\"$FEDLIN_PROJECT\""
echo ""
echo "Or scripts will use the gcloud default project"
echo ""

