#!/bin/bash
# Test Cloudflare API connection

set -euo pipefail

echo "Testing Cloudflare API Connection"
echo "=================================="
echo ""

# Check for token
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
    echo "❌ CLOUDFLARE_API_TOKEN not set"
    echo ""
    echo "Set it with:"
    echo "  export CLOUDFLARE_API_TOKEN='your-token'"
    exit 1
fi

echo "✓ Token found (length: ${#CLOUDFLARE_API_TOKEN})"
echo ""

# Test API call
echo "Testing API call to get zone info..."
response=$(curl -s -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones?name=fedlin.com")

echo "API Response:"
echo "$response" | jq '.' 2>/dev/null || echo "$response"

echo ""
if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ API connection successful!"
    zone_id=$(echo "$response" | jq -r '.result[0].id // empty')
    zone_name=$(echo "$response" | jq -r '.result[0].name // empty')
    echo "Zone ID: $zone_id"
    echo "Zone Name: $zone_name"
else
    echo "❌ API connection failed"
    error=$(echo "$response" | jq -r '.errors[0].message // "Unknown error"' 2>/dev/null)
    echo "Error: $error"
    echo ""
    echo "Common issues:"
    echo "1. Token is invalid or expired"
    echo "2. Token doesn't have 'Zone: DNS: Edit' permissions"
    echo "3. Domain 'fedlin.com' not in your Cloudflare account"
fi

