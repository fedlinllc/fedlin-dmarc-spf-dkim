#!/bin/bash
# Automated setup script for fedlin.com DNS records
# Updates SPF via Cloudflare API

set -euo pipefail

DOMAIN="fedlin.com"

echo "=========================================="
echo "Fedlin.com DNS Setup Automation"
echo "=========================================="
echo ""

# Check for Cloudflare credentials
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ] && [ -z "${CLOUDFLARE_API_KEY:-}" ]; then
    echo "⚠️  Cloudflare API credentials not found"
    echo ""
    echo "Please set one of the following:"
    echo "  export CLOUDFLARE_API_TOKEN='your-token'"
    echo "  OR"
    echo "  export CLOUDFLARE_API_KEY='your-key'"
    echo "  export CLOUDFLARE_EMAIL='your-email@example.com'"
    echo ""
    echo "See CLOUDFLARE_API_SETUP.md for detailed instructions"
    echo ""
    read -p "Do you want to continue with manual instructions? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    echo ""
    echo "=========================================="
    echo "MANUAL SETUP INSTRUCTIONS"
    echo "=========================================="
    echo ""
    echo "Since API credentials are not available, here's what needs to be done:"
    echo ""
    echo "1. UPDATE SPF RECORD in Cloudflare DNS:"
    echo "   - Go to: https://dash.cloudflare.com"
    echo "   - Select domain: fedlin.com"
    echo "   - Go to DNS → Records"
    echo "   - Find the TXT record for '@' or 'fedlin.com'"
    echo "   - Current: v=spf1 mx include:netblocks.dreamhost.com include:relay.mailchannels.net include:_spf.google.com ~all"
    echo "   - Update to: v=spf1 include:_spf.google.com ~all"
    echo "   - Save"
    echo ""
    echo "2. ADD DKIM RECORD:"
    echo "   - Go to: https://admin.google.com"
    echo "   - Navigate: Apps → Google Workspace → Gmail → Authenticate email"
    echo "   - Click 'Show authentication record' or 'Generate new record'"
    echo "   - Copy the selector (usually 'google') and TXT record value"
    echo "   - In Cloudflare DNS, add new TXT record:"
    echo "     * Name: google._domainkey (or your selector)"
    echo "     * Content: [paste full TXT value from Google]"
    echo "     * TTL: Auto"
    echo ""
    echo "3. VERIFY:"
    echo "   Run: ./verify-email-auth.sh fedlin.com"
    echo ""
    exit 0
fi

# If we have credentials, proceed with API automation
echo "✓ Cloudflare API credentials found"
echo ""

# Step 1: Update SPF record
echo "Step 1: Updating SPF record..."
NEW_SPF="v=spf1 include:_spf.google.com ~all"
./cloudflare-dns.sh "$DOMAIN" update-spf "$NEW_SPF"
echo ""

# Step 2: Show current records
echo "Step 2: Current DNS records:"
./cloudflare-dns.sh "$DOMAIN" show
echo ""

# Step 3: DKIM instructions
echo "=========================================="
echo "DKIM SETUP REQUIRED"
echo "=========================================="
echo ""
echo "DKIM cannot be automated without the public key from Google Workspace."
echo ""
echo "Please follow these steps:"
echo ""
echo "1. Get DKIM from Google Workspace:"
echo "   - Go to: https://admin.google.com"
echo "   - Navigate: Apps → Google Workspace → Gmail → Authenticate email"
echo "   - Click 'Show authentication record' or 'Generate new record'"
echo "   - Copy the selector name and full TXT record value"
echo ""
echo "2. Add via API (once you have the values):"
echo "   ./cloudflare-dns.sh fedlin.com add-dkim <selector> '<dkim_content>'"
echo ""
echo "   Example:"
echo "   ./cloudflare-dns.sh fedlin.com add-dkim google 'v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC...'"
echo ""
echo "3. Or add manually in Cloudflare Dashboard:"
echo "   - DNS → Records → Add record"
echo "   - Type: TXT"
echo "   - Name: <selector>._domainkey"
echo "   - Content: [paste full value from Google]"
echo "   - TTL: Auto"
echo ""
echo "4. Verify after adding:"
echo "   ./verify-email-auth.sh fedlin.com"
echo ""

