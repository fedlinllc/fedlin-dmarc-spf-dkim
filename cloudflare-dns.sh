#!/bin/bash
# Cloudflare DNS Management Script
# Manages SPF, DMARC, and DKIM records via Cloudflare API

set -euo pipefail

DOMAIN="${1:-fedlin.com}"

# Cloudflare API credentials
# Check environment variables first, then fall back to common locations
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL:-${CF_EMAIL:-}}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY:-${CF_API_KEY:-}}"

# API endpoint
CF_API="https://api.cloudflare.com/client/v4"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to make API request
cf_api_request() {
    local method=$1
    local endpoint=$2
    local data="${3:-}"
    
    local headers=()
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
        headers+=(-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")
    elif [ -n "$CLOUDFLARE_API_KEY" ] && [ -n "$CLOUDFLARE_EMAIL" ]; then
        headers+=(-H "X-Auth-Email: ${CLOUDFLARE_EMAIL}")
        headers+=(-H "X-Auth-Key: ${CLOUDFLARE_API_KEY}")
    else
        echo -e "${RED}Error: Cloudflare API credentials not found${NC}"
        echo "Set CLOUDFLARE_API_TOKEN or CLOUDFLARE_API_KEY + CLOUDFLARE_EMAIL"
        exit 1
    fi
    
    headers+=(-H "Content-Type: application/json")
    
    if [ "$method" = "GET" ]; then
        curl -s "${headers[@]}" "${CF_API}${endpoint}"
    else
        curl -s -X "${method}" "${headers[@]}" -d "${data}" "${CF_API}${endpoint}"
    fi
}

# Get zone ID for domain
get_zone_id() {
    local domain=$1
    local response=$(cf_api_request "GET" "/zones?name=${domain}")
    
    # Check for API errors
    if ! echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        local error_msg=$(echo "$response" | jq -r '.errors[0].message // .message // "Unknown error"' 2>/dev/null || echo "Invalid API response")
        local error_code=$(echo "$response" | jq -r '.errors[0].code // "unknown"' 2>/dev/null)
        echo -e "${RED}Error: API request failed${NC}"
        echo "Error code: $error_code"
        echo "Error message: $error_msg"
        echo ""
        # Show raw response for debugging (first 200 chars)
        echo "API Response (first 200 chars):"
        echo "$response" | head -c 200
        echo ""
        echo ""
        echo "Please check your Cloudflare API credentials:"
        echo "  - Set CLOUDFLARE_API_TOKEN environment variable, or"
        echo "  - Set CLOUDFLARE_API_KEY and CLOUDFLARE_EMAIL"
        echo "  - Verify the token has 'Zone: DNS: Edit' permissions"
        exit 1
    fi
    
    local zone_id=$(echo "$response" | jq -r '.result[0].id // empty' 2>/dev/null)
    
    if [ -z "$zone_id" ] || [ "$zone_id" = "null" ]; then
        echo -e "${RED}Error: Domain ${domain} not found in Cloudflare${NC}"
        echo "Make sure the domain is added to your Cloudflare account"
        exit 1
    fi
    
    echo "$zone_id"
}

# List DNS records
list_dns_records() {
    local zone_id=$1
    local record_type="${2:-}"
    local name="${3:-}"
    
    local endpoint="/zones/${zone_id}/dns_records"
    local params=""
    
    if [ -n "$record_type" ]; then
        params="?type=${record_type}"
        if [ -n "$name" ]; then
            params="${params}&name=${name}"
        fi
    elif [ -n "$name" ]; then
        params="?name=${name}"
    fi
    
    cf_api_request "GET" "${endpoint}${params}"
}

# Create DNS record
create_dns_record() {
    local zone_id=$1
    local record_type=$2
    local name=$3
    local content=$4
    local ttl="${5:-1}"  # 1 = auto
    
    local data=$(jq -n \
        --arg type "$record_type" \
        --arg name "$name" \
        --arg content "$content" \
        --argjson ttl "$ttl" \
        '{type: $type, name: $name, content: $content, ttl: $ttl}')
    
    cf_api_request "POST" "/zones/${zone_id}/dns_records" "$data"
}

# Update DNS record
update_dns_record() {
    local zone_id=$1
    local record_id=$2
    local record_type=$3
    local name=$4
    local content=$5
    local ttl="${6:-1}"  # 1 = auto
    
    local data=$(jq -n \
        --arg type "$record_type" \
        --arg name "$name" \
        --arg content "$content" \
        --argjson ttl "$ttl" \
        '{type: $type, name: $name, content: $content, ttl: $ttl}')
    
    cf_api_request "PUT" "/zones/${zone_id}/dns_records/${record_id}" "$data"
}

# Delete DNS record
delete_dns_record() {
    local zone_id=$1
    local record_id=$2
    
    cf_api_request "DELETE" "/zones/${zone_id}/dns_records/${record_id}"
}

# Main functions
show_current_records() {
    local zone_id=$1
    
    echo -e "${GREEN}Current DNS Records for ${DOMAIN}:${NC}"
    echo "=========================================="
    
    # SPF
    echo ""
    echo "--- SPF Records ---"
    local spf_records=$(list_dns_records "$zone_id" "TXT" "${DOMAIN}")
    echo "$spf_records" | jq -r '.result[] | select(.content | contains("v=spf1")) | "ID: \(.id)\nName: \(.name)\nContent: \(.content)\nTTL: \(.ttl)\n"'
    
    # DMARC
    echo ""
    echo "--- DMARC Records ---"
    local dmarc_records=$(list_dns_records "$zone_id" "TXT" "_dmarc.${DOMAIN}")
    echo "$dmarc_records" | jq -r '.result[] | select(.content | contains("v=DMARC1")) | "ID: \(.id)\nName: \(.name)\nContent: \(.content)\nTTL: \(.ttl)\n"'
    
    # DKIM
    echo ""
    echo "--- DKIM Records ---"
    local dkim_records=$(list_dns_records "$zone_id" "TXT")
    echo "$dkim_records" | jq -r '.result[] | select(.content | contains("v=DKIM1")) | "ID: \(.id)\nName: \(.name)\nContent: \(.content | .[0:80])...\nTTL: \(.ttl)\n"'
}

update_spf_record() {
    local zone_id=$1
    local new_spf="${2:-v=spf1 include:_spf.google.com ~all}"
    
    echo -e "${YELLOW}Updating SPF record...${NC}"
    
    # Find existing SPF record
    local spf_records=$(list_dns_records "$zone_id" "TXT" "${DOMAIN}")
    local spf_record=$(echo "$spf_records" | jq -r '.result[] | select(.content | contains("v=spf1")) | .')
    
    if [ -z "$spf_record" ] || [ "$spf_record" = "null" ]; then
        echo -e "${YELLOW}No existing SPF record found, creating new one...${NC}"
        local result=$(create_dns_record "$zone_id" "TXT" "${DOMAIN}" "$new_spf")
        if echo "$result" | jq -e '.success' > /dev/null; then
            echo -e "${GREEN}✓ SPF record created${NC}"
        else
            echo -e "${RED}✗ Failed to create SPF record${NC}"
            echo "$result" | jq '.errors'
            return 1
        fi
    else
        local record_id=$(echo "$spf_record" | jq -r '.id')
        local current_content=$(echo "$spf_record" | jq -r '.content')
        
        echo "Current SPF: $current_content"
        echo "New SPF: $new_spf"
        
        local result=$(update_dns_record "$zone_id" "$record_id" "TXT" "${DOMAIN}" "$new_spf")
        if echo "$result" | jq -e '.success' > /dev/null; then
            echo -e "${GREEN}✓ SPF record updated${NC}"
        else
            echo -e "${RED}✗ Failed to update SPF record${NC}"
            echo "$result" | jq '.errors'
            return 1
        fi
    fi
}

add_dkim_record() {
    local zone_id=$1
    local selector=$2
    local dkim_content=$3
    
    local dkim_name="${selector}._domainkey.${DOMAIN}"
    
    echo -e "${YELLOW}Adding DKIM record: ${dkim_name}${NC}"
    
    # Check if record already exists
    local existing=$(list_dns_records "$zone_id" "TXT" "$dkim_name")
    local existing_record=$(echo "$existing" | jq -r '.result[0] // empty')
    
    if [ -n "$existing_record" ] && [ "$existing_record" != "null" ]; then
        local record_id=$(echo "$existing_record" | jq -r '.id')
        echo -e "${YELLOW}DKIM record exists, updating...${NC}"
        local result=$(update_dns_record "$zone_id" "$record_id" "TXT" "$dkim_name" "$dkim_content")
    else
        echo -e "${YELLOW}Creating new DKIM record...${NC}"
        local result=$(create_dns_record "$zone_id" "TXT" "$dkim_name" "$dkim_content")
    fi
    
    if echo "$result" | jq -e '.success' > /dev/null; then
        echo -e "${GREEN}✓ DKIM record added/updated${NC}"
    else
        echo -e "${RED}✗ Failed to add DKIM record${NC}"
        echo "$result" | jq '.errors'
        return 1
    fi
}

# Main script
main() {
    local command="${1:-show}"
    
    echo "Cloudflare DNS Management for ${DOMAIN}"
    echo "=========================================="
    echo ""
    
    # Get zone ID
    echo "Getting zone ID for ${DOMAIN}..."
    local zone_id=$(get_zone_id "$DOMAIN")
    echo -e "${GREEN}Zone ID: ${zone_id}${NC}"
    echo ""
    
    case "$command" in
        show)
            show_current_records "$zone_id"
            ;;
        update-spf)
            local new_spf="${2:-v=spf1 include:_spf.google.com ~all}"
            update_spf_record "$zone_id" "$new_spf"
            ;;
        add-dkim)
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                echo -e "${RED}Usage: $0 add-dkim <selector> <dkim_content>${NC}"
                echo "Example: $0 add-dkim google 'v=DKIM1; k=rsa; p=...'"
                exit 1
            fi
            add_dkim_record "$zone_id" "$2" "$3"
            ;;
        *)
            echo "Usage: $0 [show|update-spf [new_spf]|add-dkim <selector> <content>]"
            echo ""
            echo "Commands:"
            echo "  show              - Show current SPF/DMARC/DKIM records"
            echo "  update-spf [spf]  - Update SPF record (default: Google Workspace)"
            echo "  add-dkim <sel> <content> - Add DKIM record"
            exit 1
            ;;
    esac
}

main "$@"

