#!/bin/bash
# DNS Check Script for DMARC/SPF/DKIM
# Checks DNS records for a given domain

set -euo pipefail

DOMAIN="${1:-fedlin.com}"
echo "Checking DNS records for: ${DOMAIN}"
echo "=========================================="
echo ""

# Function to check DNS record
check_record() {
    local record_type=$1
    local record_name=$2
    local description=$3
    
    echo "--- ${description} ---"
    echo "Querying: ${record_name} ${record_type}"
    
    if dig +short "${record_name}" "${record_type}" | head -1 | grep -q .; then
        echo "✓ Found:"
        dig +short "${record_name}" "${record_type}" | while read -r line; do
            echo "  ${line}"
        done
    else
        echo "✗ NOT FOUND"
    fi
    echo ""
}

# Check MX records to identify email provider
echo "--- MX Records (Email Provider) ---"
MX_RECORDS=$(dig +short "${DOMAIN}" MX | sort -n)
if [ -n "$MX_RECORDS" ]; then
    echo "✓ Found MX records:"
    echo "$MX_RECORDS" | while read -r line; do
        echo "  ${line}"
    done
    echo ""
    
    # Detect email provider
    if echo "$MX_RECORDS" | grep -qi "google\|gmail\|aspmx"; then
        EMAIL_PROVIDER="Google Workspace"
        echo "→ Detected: Google Workspace"
    elif echo "$MX_RECORDS" | grep -qi "outlook\|microsoft\|protection"; then
        EMAIL_PROVIDER="Microsoft 365"
        echo "→ Detected: Microsoft 365"
    elif echo "$MX_RECORDS" | grep -qi "cloudflare\|cf"; then
        EMAIL_PROVIDER="Cloudflare Email Routing"
        echo "→ Detected: Cloudflare Email Routing"
    else
        EMAIL_PROVIDER="Unknown"
        echo "→ Provider: Unknown (check MX records above)"
    fi
else
    echo "✗ No MX records found"
    EMAIL_PROVIDER="Unknown"
fi
echo ""

# Check SPF record
check_record TXT "${DOMAIN}" "SPF Record (TXT at root)"

# Analyze SPF record
SPF_RECORD=$(dig +short "${DOMAIN}" TXT | grep "v=spf1" | head -1)
if [ -n "$SPF_RECORD" ]; then
    if echo "$SPF_RECORD" | grep -q "dreamhost"; then
        echo "⚠️  WARNING: SPF record still contains Dreamhost references!"
        echo "   Update SPF to remove Dreamhost after migration."
        echo ""
    fi
fi

# Check DMARC record
check_record TXT "_dmarc.${DOMAIN}" "DMARC Record"

# Check common DKIM selectors
# Cloudflare Email Routing typically uses selectors like:
# - cloudflare (for Cloudflare Email Routing)
# - selector1, selector2 (common defaults)
# - google._domainkey (if using Google Workspace)
# - selector1-mail, selector2-mail (Microsoft 365)
echo "--- DKIM Records ---"
echo "Checking common DKIM selectors..."

# Build DKIM selector list based on detected provider
DKIM_SELECTORS=(
    "cloudflare._domainkey"
    "cf._domainkey"
    "selector1._domainkey"
    "selector2._domainkey"
    "google._domainkey"
    "selector1-mail._domainkey"
    "selector2-mail._domainkey"
    "default._domainkey"
    "s1._domainkey"
    "s2._domainkey"
)

# Add provider-specific selectors
if [ "$EMAIL_PROVIDER" = "Google Workspace" ]; then
    DKIM_SELECTORS+=("google._domainkey")
elif [ "$EMAIL_PROVIDER" = "Microsoft 365" ]; then
    DKIM_SELECTORS+=("selector1-mail._domainkey" "selector2-mail._domainkey")
elif [ "$EMAIL_PROVIDER" = "Cloudflare Email Routing" ]; then
    DKIM_SELECTORS+=("cloudflare._domainkey" "cf._domainkey")
fi

DKIM_FOUND=false
for selector in "${DKIM_SELECTORS[@]}"; do
    record_name="${selector}.${DOMAIN}"
    if dig +short "${record_name}" TXT | head -1 | grep -q "v=DKIM1"; then
        echo "✓ Found DKIM: ${selector}"
        dig +short "${record_name}" TXT | while read -r line; do
            echo "  ${line}"
        done
        DKIM_FOUND=true
        echo ""
    fi
done

if [ "$DKIM_FOUND" = false ]; then
    echo "✗ No DKIM records found for common selectors"
    echo ""
    echo "⚠️  ACTION REQUIRED:"
    echo "   1. Check your email provider's dashboard for DKIM settings:"
    if [ "$EMAIL_PROVIDER" = "Google Workspace" ]; then
        echo "      → Google Admin Console → Apps → Google Workspace → Gmail →"
        echo "        Authenticate email → Show DKIM authentication record"
    elif [ "$EMAIL_PROVIDER" = "Microsoft 365" ]; then
        echo "      → Microsoft 365 Admin → Exchange Admin Center → Mail flow →"
        echo "        DKIM → Enable and get selector"
    elif [ "$EMAIL_PROVIDER" = "Cloudflare Email Routing" ]; then
        echo "      → Cloudflare Dashboard → Email → Email Routing →"
        echo "        Destination addresses → View DKIM settings"
    else
        echo "      → Check your email provider's documentation for DKIM setup"
    fi
    echo "   2. Add the DKIM TXT record to Cloudflare DNS"
    echo "   3. Re-run this check to verify"
fi

echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
SPF_STATUS=$(dig +short ${DOMAIN} TXT | grep -q 'v=spf1' && echo '✓ Found' || echo '✗ Missing')
DMARC_STATUS=$(dig +short _dmarc.${DOMAIN} TXT | grep -q 'v=DMARC1' && echo '✓ Found' || echo '✗ Missing')
DKIM_STATUS=$([ "$DKIM_FOUND" = true ] && echo '✓ Found' || echo '✗ Missing')

echo "- SPF:     ${SPF_STATUS}"
echo "- DMARC:   ${DMARC_STATUS}"
echo "- DKIM:    ${DKIM_STATUS}"
echo "- Provider: ${EMAIL_PROVIDER}"
echo ""

# Final recommendations
if [ "$DKIM_FOUND" = false ] || echo "$SPF_RECORD" | grep -q "dreamhost"; then
    echo "⚠️  RECOMMENDATIONS:"
    if [ "$DKIM_FOUND" = false ]; then
        echo "   • Add DKIM record (required for email authentication)"
    fi
    if echo "$SPF_RECORD" | grep -q "dreamhost"; then
        echo "   • Update SPF record to remove Dreamhost references"
        if [ "$EMAIL_PROVIDER" = "Google Workspace" ]; then
            echo "     Suggested: v=spf1 include:_spf.google.com ~all"
        elif [ "$EMAIL_PROVIDER" = "Microsoft 365" ]; then
            echo "     Suggested: v=spf1 include:spf.protection.outlook.com ~all"
        fi
    fi
    echo ""
fi

