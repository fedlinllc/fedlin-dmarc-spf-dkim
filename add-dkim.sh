#!/bin/bash
# Helper script to add DKIM record via Cloudflare API
# Usage: ./add-dkim.sh [selector] [dkim_content]

set -euo pipefail

DOMAIN="fedlin.com"
SELECTOR="${1:-}"
DKIM_CONTENT="${2:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Add DKIM Record via Cloudflare API"
echo "Domain: ${DOMAIN}"
echo "=========================================="
echo ""

# Check for credentials
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ] && [ -z "${CLOUDFLARE_API_KEY:-}" ]; then
    echo -e "${RED}Error: Cloudflare API credentials not found${NC}"
    echo ""
    echo "Please set one of:"
    echo "  export CLOUDFLARE_API_TOKEN='your-token'"
    echo "  OR"
    echo "  export CLOUDFLARE_API_KEY='your-key'"
    echo "  export CLOUDFLARE_EMAIL='your-email@example.com'"
    echo ""
    exit 1
fi

# If selector and content not provided, prompt for them
if [ -z "$SELECTOR" ] || [ -z "$DKIM_CONTENT" ]; then
    echo "To add DKIM, you need:"
    echo "1. Selector name (usually 'google' for Google Workspace)"
    echo "2. Full DKIM TXT record content"
    echo ""
    echo "Get these from Google Workspace Admin Console:"
    echo "  https://admin.google.com"
    echo "  Apps → Google Workspace → Gmail → Authenticate email"
    echo ""
    
    if [ -z "$SELECTOR" ]; then
        read -p "Enter DKIM selector (default: google): " SELECTOR
        SELECTOR="${SELECTOR:-google}"
    fi
    
    if [ -z "$DKIM_CONTENT" ]; then
        echo ""
        echo "Paste the full DKIM TXT record content from Google Workspace."
        echo "It should start with 'v=DKIM1; k=rsa; p=...'"
        echo "You can paste multiple lines - press Ctrl+D when done:"
        echo ""
        DKIM_CONTENT=$(cat)
    fi
fi

# Clean up DKIM content (remove quotes, newlines, etc.)
DKIM_CONTENT=$(echo "$DKIM_CONTENT" | tr -d '\n' | sed 's/^"//;s/"$//' | xargs)

# Validate DKIM content
if ! echo "$DKIM_CONTENT" | grep -qi "v=dkim1"; then
    echo -e "${YELLOW}Warning: DKIM content doesn't appear to start with 'v=DKIM1'${NC}"
    echo "Content preview: ${DKIM_CONTENT:0:50}..."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Adding DKIM record...${NC}"
echo "Selector: ${SELECTOR}"
echo "Record name: ${SELECTOR}._domainkey.${DOMAIN}"
echo "Content length: ${#DKIM_CONTENT} characters"
echo ""

# Use the cloudflare-dns.sh script to add DKIM
if ./cloudflare-dns.sh "$DOMAIN" add-dkim "$SELECTOR" "$DKIM_CONTENT"; then
    echo ""
    echo -e "${GREEN}✓ DKIM record added successfully!${NC}"
    echo ""
    echo "Verifying DNS propagation..."
    sleep 2
    
    # Check if record is visible
    dkim_record=$(dig +short "${SELECTOR}._domainkey.${DOMAIN}" TXT 2>/dev/null | grep -i "v=dkim1" | head -1 || echo "")
    if [ -n "$dkim_record" ]; then
        echo -e "${GREEN}✓ DKIM record is visible in DNS${NC}"
    else
        echo -e "${YELLOW}⚠ DKIM record not yet visible (may take a few minutes to propagate)${NC}"
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Wait 5-15 minutes for DNS propagation"
    echo "2. Verify: ./verify-email-auth.sh ${DOMAIN}"
    echo "3. Send a test email and check headers"
else
    echo ""
    echo -e "${RED}✗ Failed to add DKIM record${NC}"
    exit 1
fi

