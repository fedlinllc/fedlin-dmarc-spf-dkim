#!/bin/bash
# Interactive Cloudflare API setup and DNS configuration

set -euo pipefail

DOMAIN="fedlin.com"

echo "=========================================="
echo "Cloudflare API Setup & DNS Configuration"
echo "Domain: ${DOMAIN}"
echo "=========================================="
echo ""

# Check for existing credentials
if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    echo "✓ Using CLOUDFLARE_API_TOKEN from environment"
    USE_TOKEN=true
elif [ -n "${CLOUDFLARE_API_KEY:-}" ] && [ -n "${CLOUDFLARE_EMAIL:-}" ]; then
    echo "✓ Using CLOUDFLARE_API_KEY and CLOUDFLARE_EMAIL from environment"
    USE_TOKEN=false
else
    echo "Cloudflare API credentials not found in environment"
    echo ""
    echo "Please provide credentials:"
    echo "1. API Token (recommended) - https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Global API Key + Email (alternative)"
    echo ""
    read -p "Enter choice (1 or 2): " choice
    
    if [ "$choice" = "1" ]; then
        read -sp "Enter Cloudflare API Token: " token
        echo ""
        export CLOUDFLARE_API_TOKEN="$token"
        USE_TOKEN=true
    elif [ "$choice" = "2" ]; then
        read -p "Enter Cloudflare Email: " email
        read -sp "Enter Cloudflare Global API Key: " key
        echo ""
        export CLOUDFLARE_EMAIL="$email"
        export CLOUDFLARE_API_KEY="$key"
        USE_TOKEN=false
    else
        echo "Invalid choice. Exiting."
        exit 1
    fi
fi

echo ""
echo "Testing API connection..."

# Test API connection
if [ "$USE_TOKEN" = true ]; then
    response=$(curl -s -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/user/tokens/verify")
else
    response=$(curl -s -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
        -H "X-Auth-Key: ${CLOUDFLARE_API_KEY}" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/user/tokens/verify")
fi

if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ API connection successful"
else
    echo "✗ API connection failed"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    exit 1
fi

echo ""
echo "=========================================="
echo "Proceeding with DNS configuration..."
echo "=========================================="
echo ""

# Now run the setup script
exec ./setup-fedlin.sh

