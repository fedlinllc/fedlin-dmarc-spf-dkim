#!/bin/bash
# Comprehensive Email Authentication Verification Script
# Checks SPF, DKIM, DMARC and provides detailed validation

set -euo pipefail

DOMAIN="${1:-fedlin.com}"
echo "=========================================="
echo "Email Authentication Verification"
echo "Domain: ${DOMAIN}"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check and validate DNS record
check_and_validate() {
    local record_type=$1
    local record_name=$2
    local description=$3
    local validation_pattern=$4
    
    echo "--- ${description} ---"
    echo "Querying: ${record_name} ${record_type}"
    
    local result=$(dig +short "${record_name}" "${record_type}" 2>/dev/null | head -1 || echo "")
    
    if [ -z "$result" ]; then
        echo -e "${RED}✗ NOT FOUND${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Found:${NC}"
    dig +short "${record_name}" "${record_type}" | while read -r line; do
        echo "  ${line}"
    done
    
    # Validate pattern if provided
    if [ -n "$validation_pattern" ]; then
        if echo "$result" | grep -qi "$validation_pattern"; then
            echo -e "${GREEN}  ✓ Valid format${NC}"
        else
            echo -e "${YELLOW}  ⚠ Format may be incorrect${NC}"
        fi
    fi
    
    echo ""
    return 0
}

# Check MX records
echo "--- Email Provider Detection ---"
MX_RECORDS=$(dig +short "${DOMAIN}" MX 2>/dev/null | sort -n || echo "")
if [ -n "$MX_RECORDS" ]; then
    echo "MX Records:"
    echo "$MX_RECORDS" | while read -r line; do
        echo "  ${line}"
    done
    
    if echo "$MX_RECORDS" | grep -qi "google\|gmail\|aspmx"; then
        EMAIL_PROVIDER="Google Workspace"
        echo -e "${GREEN}→ Detected: Google Workspace${NC}"
    elif echo "$MX_RECORDS" | grep -qi "outlook\|microsoft\|protection"; then
        EMAIL_PROVIDER="Microsoft 365"
        echo -e "${GREEN}→ Detected: Microsoft 365${NC}"
    else
        EMAIL_PROVIDER="Unknown"
        echo -e "${YELLOW}→ Provider: Unknown${NC}"
    fi
else
    echo -e "${RED}✗ No MX records found${NC}"
    EMAIL_PROVIDER="Unknown"
fi
echo ""

# Check SPF
SPF_FOUND=false
SPF_RECORD=$(dig +short "${DOMAIN}" TXT 2>/dev/null | grep -i "v=spf1" | head -1 || echo "")
if [ -n "$SPF_RECORD" ]; then
    SPF_FOUND=true
    echo "--- SPF Record ---"
    echo -e "${GREEN}✓ Found:${NC}"
    echo "  ${SPF_RECORD}"
    
    # Validate SPF
    if echo "$SPF_RECORD" | grep -qi "v=spf1"; then
        echo -e "${GREEN}  ✓ Valid SPF format${NC}"
    fi
    
    # Check for issues
    if echo "$SPF_RECORD" | grep -qi "dreamhost"; then
        echo -e "${YELLOW}  ⚠ Contains Dreamhost references (should be removed)${NC}"
    fi
    
    if echo "$SPF_RECORD" | grep -qi "include:_spf.google.com"; then
        echo -e "${GREEN}  ✓ Includes Google Workspace SPF${NC}"
    elif echo "$SPF_RECORD" | grep -qi "include:spf.protection.outlook.com"; then
        echo -e "${GREEN}  ✓ Includes Microsoft 365 SPF${NC}"
    fi
    
    # Check SPF mechanism
    if echo "$SPF_RECORD" | grep -qE "[\s~]all[\s\"]"; then
        echo -e "${GREEN}  ✓ Has 'all' mechanism${NC}"
    fi
else
    echo "--- SPF Record ---"
    echo -e "${RED}✗ NOT FOUND${NC}"
fi
echo ""

# Check DMARC
DMARC_FOUND=false
DMARC_RECORD=$(dig +short "_dmarc.${DOMAIN}" TXT 2>/dev/null | grep -i "v=dmarc1" | head -1 || echo "")
if [ -n "$DMARC_RECORD" ]; then
    DMARC_FOUND=true
    echo "--- DMARC Record ---"
    echo -e "${GREEN}✓ Found:${NC}"
    echo "  ${DMARC_RECORD}"
    
    # Validate DMARC
    if echo "$DMARC_RECORD" | grep -qi "v=dmarc1"; then
        echo -e "${GREEN}  ✓ Valid DMARC format${NC}"
    fi
    
    # Check policy
    if echo "$DMARC_RECORD" | grep -qi "p=none"; then
        echo -e "${GREEN}  ✓ Policy: none (monitoring mode)${NC}"
    elif echo "$DMARC_RECORD" | grep -qi "p=quarantine"; then
        echo -e "${YELLOW}  ⚠ Policy: quarantine${NC}"
    elif echo "$DMARC_RECORD" | grep -qi "p=reject"; then
        echo -e "${YELLOW}  ⚠ Policy: reject${NC}"
    fi
    
    # Check reporting
    if echo "$DMARC_RECORD" | grep -qi "rua="; then
        echo -e "${GREEN}  ✓ Aggregate reports configured${NC}"
    fi
else
    echo "--- DMARC Record ---"
    echo -e "${RED}✗ NOT FOUND${NC}"
fi
echo ""

# Check DKIM - comprehensive check
echo "--- DKIM Records ---"
DKIM_FOUND=false
DKIM_COUNT=0

# Google Workspace DKIM selectors
if [ "$EMAIL_PROVIDER" = "Google Workspace" ]; then
    DKIM_SELECTORS=(
        "google._domainkey"
        "default._domainkey"
    )
else
    DKIM_SELECTORS=(
        "google._domainkey"
        "selector1._domainkey"
        "selector2._domainkey"
        "selector1-mail._domainkey"
        "selector2-mail._domainkey"
        "cloudflare._domainkey"
        "cf._domainkey"
        "default._domainkey"
    )
fi

for selector in "${DKIM_SELECTORS[@]}"; do
    record_name="${selector}.${DOMAIN}"
    dkim_record=$(dig +short "${record_name}" TXT 2>/dev/null | grep -i "v=dkim1" | head -1 || echo "")
    
    if [ -n "$dkim_record" ]; then
        DKIM_FOUND=true
        DKIM_COUNT=$((DKIM_COUNT + 1))
        echo -e "${GREEN}✓ Found DKIM: ${selector}${NC}"
        
        # Extract key type and validate
        if echo "$dkim_record" | grep -qi "k=rsa"; then
            echo -e "${GREEN}  ✓ Key type: RSA${NC}"
        fi
        
        # Check if public key is present
        if echo "$dkim_record" | grep -qi "p="; then
            key_length=$(echo "$dkim_record" | grep -oP 'p=[^;"]+' | cut -d= -f2 | wc -c)
            if [ "$key_length" -gt 100 ]; then
                echo -e "${GREEN}  ✓ Public key present${NC}"
            else
                echo -e "${YELLOW}  ⚠ Public key may be incomplete${NC}"
            fi
        fi
    fi
done

if [ "$DKIM_FOUND" = false ]; then
    echo -e "${RED}✗ No DKIM records found${NC}"
    echo ""
    echo -e "${YELLOW}ACTION REQUIRED:${NC}"
    if [ "$EMAIL_PROVIDER" = "Google Workspace" ]; then
        echo "1. Go to: https://admin.google.com"
        echo "2. Navigate: Apps → Google Workspace → Gmail → Authenticate email"
        echo "3. Click 'Generate new record' or 'Show authentication record'"
        echo "4. Copy the selector name (usually 'google') and the TXT record value"
        echo "5. Add TXT record in Cloudflare DNS:"
        echo "   - Name: google._domainkey (or the selector shown)"
        echo "   - Content: [paste the full TXT record value]"
        echo "   - TTL: Auto"
    else
        echo "Check your email provider's documentation for DKIM setup instructions"
    fi
else
    echo ""
    echo -e "${GREEN}✓ Found ${DKIM_COUNT} DKIM record(s)${NC}"
fi
echo ""

# Final validation summary
echo "=========================================="
echo "VALIDATION SUMMARY"
echo "=========================================="

if [ "$SPF_FOUND" = true ]; then
    echo -e "SPF:     ${GREEN}✓ Configured${NC}"
    if echo "$SPF_RECORD" | grep -qi "dreamhost"; then
        echo -e "         ${YELLOW}⚠ Needs cleanup (remove Dreamhost)${NC}"
    fi
else
    echo -e "SPF:     ${RED}✗ Missing${NC}"
fi

if [ "$DMARC_FOUND" = true ]; then
    echo -e "DMARC:   ${GREEN}✓ Configured${NC}"
else
    echo -e "DMARC:   ${RED}✗ Missing${NC}"
fi

if [ "$DKIM_FOUND" = true ]; then
    echo -e "DKIM:    ${GREEN}✓ Configured (${DKIM_COUNT} record(s))${NC}"
else
    echo -e "DKIM:    ${RED}✗ Missing${NC}"
fi

echo ""

# Overall status
ALL_CONFIGURED=true
if [ "$SPF_FOUND" = false ] || [ "$DMARC_FOUND" = false ] || [ "$DKIM_FOUND" = false ]; then
    ALL_CONFIGURED=false
fi

if [ "$ALL_CONFIGURED" = true ] && ! echo "$SPF_RECORD" | grep -qi "dreamhost"; then
    echo -e "${GREEN}✓ All email authentication records are properly configured!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Send a test email and check headers"
    echo "2. Use tools like:"
    echo "   - https://mxtoolbox.com/emailhealth/"
    echo "   - https://www.mail-tester.com/"
    echo "   - https://toolbox.googleapps.com/apps/checkmx/check"
else
    echo -e "${YELLOW}⚠ Configuration incomplete${NC}"
    echo ""
    echo "Required actions:"
    if [ "$DKIM_FOUND" = false ]; then
        echo "  • Add DKIM record"
    fi
    if echo "$SPF_RECORD" | grep -qi "dreamhost"; then
        echo "  • Update SPF to remove Dreamhost references"
    fi
fi

echo ""

