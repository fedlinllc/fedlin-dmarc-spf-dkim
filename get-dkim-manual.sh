#!/bin/bash
# Manual DKIM retrieval - Get from Google Admin Console, add via Cloudflare API
# This avoids OAuth issues with Admin SDK

set -euo pipefail

DOMAIN="${1:-fedlin.com}"
SELECTOR="${2:-google}"

echo "=========================================="
echo "DKIM Setup - Manual Method"
echo "Domain: ${DOMAIN}"
echo "=========================================="
echo ""
echo "Since OAuth is blocked, we'll get DKIM from Google Admin Console"
echo "and add it to Cloudflare via API."
echo ""

# Check for Cloudflare credentials
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ] && [ -z "${CLOUDFLARE_API_KEY:-}" ]; then
    echo "⚠️  Cloudflare API credentials not found"
    echo ""
    echo "Please set:"
    echo "  export CLOUDFLARE_API_TOKEN='your-token'"
    echo ""
    read -p "Enter Cloudflare API Token (or press Enter to skip Cloudflare step): " cf_token
    if [ -n "$cf_token" ]; then
        export CLOUDFLARE_API_TOKEN="$cf_token"
    else
        echo "Skipping Cloudflare DNS update - will show manual instructions"
    fi
fi

echo ""
echo "=========================================="
echo "Step 1: Get DKIM from Google Admin Console"
echo "=========================================="
echo ""
echo "1. Go to: https://admin.google.com"
echo "2. Navigate: Apps → Google Workspace → Gmail → Authenticate email"
echo "3. Select domain: ${DOMAIN}"
echo "4. Click 'Show authentication record' or 'Generate new record'"
echo "5. Copy the selector name and full TXT record value"
echo ""
echo "The DKIM record will look like:"
echo "  v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
echo ""

read -p "Enter DKIM selector (default: ${SELECTOR}): " input_selector
SELECTOR="${input_selector:-$SELECTOR}"

echo ""
echo "Paste the full DKIM TXT record content from Google:"
echo "(It should start with 'v=DKIM1; k=rsa; p=...')"
echo "You can paste multiple lines - press Ctrl+D when done:"
echo ""

DKIM_CONTENT=$(cat)

# Clean up DKIM content
DKIM_CONTENT=$(echo "$DKIM_CONTENT" | tr -d '\n' | sed 's/^"//;s/"$//' | xargs)

# Validate
if ! echo "$DKIM_CONTENT" | grep -qi "v=dkim1"; then
    echo ""
    echo "⚠️  Warning: DKIM content doesn't appear to start with 'v=DKIM1'"
    echo "Content preview: ${DKIM_CONTENT:0:50}..."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "DKIM Information"
echo "=========================================="
echo "Selector: ${SELECTOR}"
echo "Record name: ${SELECTOR}._domainkey.${DOMAIN}"
echo "Content length: ${#DKIM_CONTENT} characters"
echo ""

# Add to Cloudflare if credentials available
if [ -n "${CLOUDFLARE_API_TOKEN:-}" ] || [ -n "${CLOUDFLARE_API_KEY:-}" ]; then
    echo "=========================================="
    echo "Step 2: Adding to Cloudflare DNS"
    echo "=========================================="
    echo ""
    
    if ./cloudflare-dns.sh "$DOMAIN" add-dkim "$SELECTOR" "$DKIM_CONTENT"; then
        echo ""
        echo "✓ DKIM record added to Cloudflare DNS!"
        echo ""
        echo "Next steps:"
        echo "1. Wait 5-15 minutes for DNS propagation"
        echo "2. Verify: ./verify-email-auth.sh ${DOMAIN}"
        echo "3. In Google Admin Console, enable DKIM authentication"
    else
        echo ""
        echo "✗ Failed to add to Cloudflare DNS"
        echo ""
        echo "Add manually in Cloudflare Dashboard:"
        echo "  DNS → Records → Add record"
        echo "  Type: TXT"
        echo "  Name: ${SELECTOR}._domainkey"
        echo "  Content: ${DKIM_CONTENT}"
        echo "  TTL: Auto"
    fi
else
    echo "=========================================="
    echo "Manual DNS Setup Required"
    echo "=========================================="
    echo ""
    echo "Add this TXT record to Cloudflare DNS:"
    echo ""
    echo "  Type: TXT"
    echo "  Name: ${SELECTOR}._domainkey"
    echo "  Content: ${DKIM_CONTENT}"
    echo "  TTL: Auto"
    echo ""
    echo "Or set CLOUDFLARE_API_TOKEN and run this script again"
fi

