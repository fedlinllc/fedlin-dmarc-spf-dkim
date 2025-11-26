#!/bin/bash
# Google Workspace Admin API - Get/Generate DKIM Keys
# Then adds to Cloudflare DNS via API

set -euo pipefail

DOMAIN="${1:-fedlin.com}"
SELECTOR="${2:-google}"
GCP_PROJECT="${GCP_PROJECT:-${GOOGLE_CLOUD_PROJECT:-fedlin}}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Google Workspace DKIM via Admin API"
echo "Domain: ${DOMAIN}"
echo "=========================================="
echo ""

# Check for Google API credentials - prefer OAuth via gcloud
USE_GCLOUD=false
USE_OAUTH=false

if [ -n "${GOOGLE_ACCESS_TOKEN:-}" ]; then
    echo -e "${GREEN}✓ Using GOOGLE_ACCESS_TOKEN${NC}"
    USE_OAUTH=true
elif command -v gcloud >/dev/null 2>&1; then
    echo "Checking gcloud OAuth authentication..."
    if gcloud auth application-default print-access-token >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Using gcloud application-default credentials (OAuth)${NC}"
        USE_GCLOUD=true
        USE_OAUTH=true
    elif gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo -e "${YELLOW}gcloud is authenticated but application-default credentials not set${NC}"
        echo "Setting up OAuth application-default credentials with Admin SDK scopes..."
        echo ""
        echo "This will open a browser for OAuth authentication..."
        echo "Make sure to grant Admin SDK API permissions"
        if gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.domain --no-launch-browser 2>&1 | grep -q "verification code"; then
            echo -e "${YELLOW}Please complete OAuth in your browser and enter the verification code${NC}"
            gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.domain
            USE_GCLOUD=true
            USE_OAUTH=true
        else
            # Non-interactive - try to use current auth
            echo -e "${YELLOW}Attempting to use current gcloud OAuth credentials...${NC}"
            USE_GCLOUD=true
            USE_OAUTH=true
        fi
    else
        echo -e "${YELLOW}gcloud not authenticated. Setting up OAuth...${NC}"
        echo "This will open a browser for OAuth authentication"
        gcloud auth login --no-launch-browser 2>&1 | head -5 || {
            echo "Please run: gcloud auth login"
            exit 1
        }
        gcloud auth application-default login --no-launch-browser 2>&1 | head -5 || {
            echo "Please run: gcloud auth application-default login"
            exit 1
        }
        USE_GCLOUD=true
        USE_OAUTH=true
    fi
elif [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    echo -e "${YELLOW}Using service account credentials${NC}"
    echo "Note: For OAuth, use gcloud instead"
    USE_GCLOUD=false
    USE_OAUTH=false
    else
        echo -e "${YELLOW}No Google API credentials found${NC}"
        echo ""
        echo "Setting up OAuth authentication with Admin SDK scopes..."
        echo ""
        if command -v gcloud >/dev/null 2>&1; then
            echo "Using gcloud OAuth (recommended)..."
            echo "This will open a browser for authentication"
            echo "Make sure to grant Admin SDK API permissions"
            gcloud auth login
            gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.domain
            USE_GCLOUD=true
            USE_OAUTH=true
    else
        echo "Error: gcloud CLI not found"
        echo "Install gcloud CLI for OAuth authentication"
        echo "Or set GOOGLE_ACCESS_TOKEN with an OAuth token"
        exit 1
    fi
fi

# Function to get access token via OAuth with correct scopes
get_access_token() {
    if [ -n "${GOOGLE_ACCESS_TOKEN:-}" ]; then
        echo "${GOOGLE_ACCESS_TOKEN}"
    elif [ "$USE_GCLOUD" = true ] && command -v gcloud >/dev/null 2>&1; then
        # Use gcloud OAuth credentials with Admin SDK scopes
        # Check if we can get a token with the right scopes
        # Note: cloud-platform scope is required by gcloud
        local token=$(gcloud auth application-default print-access-token --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.domain 2>/dev/null)
        if [ -n "$token" ]; then
            echo "$token"
            return 0
        fi
        
        # Try without scope specification (may work if scopes were granted)
        if gcloud auth application-default print-access-token 2>/dev/null; then
            # Success - token printed
            return 0
        else
            echo -e "${RED}Error: OAuth credentials not available${NC}"
            echo "Run: gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/admin.directory.domain"
            return 1
        fi
    elif [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
        # Fallback to service account if provided
        if command -v gcloud >/dev/null 2>&1; then
            gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}" >/dev/null 2>&1
            gcloud auth application-default print-access-token 2>/dev/null || {
                echo -e "${RED}Error: Service account authentication failed${NC}"
                return 1
            }
        else
            echo -e "${RED}Error: gcloud CLI required${NC}"
            return 1
        fi
    else
        echo -e "${RED}Error: No authentication method available${NC}"
        echo "Set up OAuth: gcloud auth application-default login"
        return 1
    fi
}

# Set GCP project if specified
if [ -n "$GCP_PROJECT" ] && [ "$GCP_PROJECT" != "fedlin" ]; then
    echo -e "${BLUE}Setting GCP project to: ${GCP_PROJECT}${NC}"
    gcloud config set project "$GCP_PROJECT" 2>/dev/null || echo -e "${YELLOW}Note: Could not set project (may need to authenticate)${NC}"
fi

# Get access token
echo -e "${BLUE}Getting Google API access token...${NC}"
ACCESS_TOKEN=$(get_access_token 2>/dev/null)
if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}Failed to get access token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Access token obtained${NC}"
echo ""

# Google Admin API endpoint
# Customer ID can be "my_customer" for most cases
CUSTOMER_ID="${GOOGLE_CUSTOMER_ID:-my_customer}"
API_BASE="https://admin.googleapis.com/admin/directory/v1"

# Function to get DKIM keys
get_dkim_keys() {
    local domain=$1
    local url="${API_BASE}/customer/${CUSTOMER_ID}/domains/${domain}/dkim"
    
    echo -e "${BLUE}Fetching DKIM keys for ${domain}...${NC}"
    local response=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        "$url")
    
    # Check for errors
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local error=$(echo "$response" | jq -r '.error.message // .error' 2>/dev/null)
        echo -e "${RED}API Error: ${error}${NC}"
        return 1
    fi
    
    echo "$response"
}

# Function to generate DKIM key
generate_dkim_key() {
    local domain=$1
    local selector=$2
    local url="${API_BASE}/customer/${CUSTOMER_ID}/domains/${domain}/dkim"
    
    echo -e "${BLUE}Generating DKIM key for selector: ${selector}...${NC}"
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"selector\":\"${selector}\"}" \
        "$url")
    
    # Check for errors
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local error=$(echo "$response" | jq -r '.error.message // .error' 2>/dev/null)
        echo -e "${RED}API Error: ${error}${NC}"
        return 1
    fi
    
    echo "$response"
}

# Get existing DKIM keys
echo "Checking for existing DKIM keys..."
DKIM_RESPONSE=$(get_dkim_keys "$DOMAIN")

if [ $? -eq 0 ] && echo "$DKIM_RESPONSE" | jq -e '.dkimKeys' >/dev/null 2>&1; then
    DKIM_KEYS=$(echo "$DKIM_RESPONSE" | jq -r '.dkimKeys[]? // empty' 2>/dev/null)
    
    if [ -n "$DKIM_KEYS" ] && [ "$DKIM_KEYS" != "null" ]; then
        echo -e "${GREEN}✓ Found existing DKIM keys${NC}"
        echo ""
        echo "$DKIM_RESPONSE" | jq -r '.dkimKeys[]? | "Selector: \(.selector // "unknown")\nPublic Key: \(.publicKey // "none")\n"' 2>/dev/null || echo "$DKIM_RESPONSE"
        
        # Try to find the selector we want
        SELECTOR_KEY=$(echo "$DKIM_RESPONSE" | jq -r --arg sel "$SELECTOR" '.dkimKeys[]? | select(.selector == $sel) | .publicKey' 2>/dev/null)
        
        if [ -n "$SELECTOR_KEY" ] && [ "$SELECTOR_KEY" != "null" ]; then
            echo ""
            echo -e "${GREEN}Found DKIM key for selector: ${SELECTOR}${NC}"
            DKIM_PUBLIC_KEY="$SELECTOR_KEY"
        else
            echo ""
            echo -e "${YELLOW}Selector '${SELECTOR}' not found. Generating new key...${NC}"
            GENERATE_RESPONSE=$(generate_dkim_key "$DOMAIN" "$SELECTOR")
            if [ $? -eq 0 ]; then
                DKIM_PUBLIC_KEY=$(echo "$GENERATE_RESPONSE" | jq -r '.publicKey // empty' 2>/dev/null)
                if [ -n "$DKIM_PUBLIC_KEY" ] && [ "$DKIM_PUBLIC_KEY" != "null" ]; then
                    echo -e "${GREEN}✓ DKIM key generated${NC}"
                else
                    echo -e "${RED}Failed to extract public key from response${NC}"
                    exit 1
                fi
            else
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}No existing DKIM keys found. Generating new key...${NC}"
        GENERATE_RESPONSE=$(generate_dkim_key "$DOMAIN" "$SELECTOR")
        if [ $? -eq 0 ]; then
            DKIM_PUBLIC_KEY=$(echo "$GENERATE_RESPONSE" | jq -r '.publicKey // empty' 2>/dev/null)
            if [ -n "$DKIM_PUBLIC_KEY" ] && [ "$DKIM_PUBLIC_KEY" != "null" ]; then
                echo -e "${GREEN}✓ DKIM key generated${NC}"
            else
                echo -e "${RED}Failed to extract public key from response${NC}"
                exit 1
            fi
        else
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}Could not fetch DKIM keys. Attempting to generate...${NC}"
    GENERATE_RESPONSE=$(generate_dkim_key "$DOMAIN" "$SELECTOR")
    if [ $? -eq 0 ]; then
        DKIM_PUBLIC_KEY=$(echo "$GENERATE_RESPONSE" | jq -r '.publicKey // empty' 2>/dev/null)
        if [ -n "$DKIM_PUBLIC_KEY" ] && [ "$DKIM_PUBLIC_KEY" != "null" ]; then
            echo -e "${GREEN}✓ DKIM key generated${NC}"
        else
            echo -e "${RED}Failed to extract public key from response${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

if [ -z "${DKIM_PUBLIC_KEY:-}" ]; then
    echo -e "${RED}Error: Could not get or generate DKIM public key${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "DKIM Key Retrieved"
echo "=========================================="
echo "Selector: ${SELECTOR}"
echo "Public Key (first 50 chars): ${DKIM_PUBLIC_KEY:0:50}..."
echo ""

# Construct DKIM TXT record
DKIM_TXT="v=DKIM1; k=rsa; p=${DKIM_PUBLIC_KEY}"

echo "DKIM TXT Record:"
echo "${DKIM_TXT:0:100}..."
echo ""

# Check for Cloudflare API credentials
if [ -z "${CLOUDFLARE_API_TOKEN:-}" ] && [ -z "${CLOUDFLARE_API_KEY:-}" ]; then
    echo -e "${YELLOW}Cloudflare API credentials not found${NC}"
    echo ""
    echo "DKIM key retrieved from Google Workspace:"
    echo "Selector: ${SELECTOR}"
    echo "TXT Record: ${DKIM_TXT}"
    echo ""
    echo "To add to Cloudflare DNS, set credentials and run:"
    echo "  export CLOUDFLARE_API_TOKEN='your-token'"
    echo "  ./cloudflare-dns.sh ${DOMAIN} add-dkim ${SELECTOR} '${DKIM_TXT}'"
    exit 0
fi

# Add to Cloudflare DNS
echo -e "${BLUE}Adding DKIM record to Cloudflare DNS...${NC}"
if ./cloudflare-dns.sh "$DOMAIN" add-dkim "$SELECTOR" "$DKIM_TXT"; then
    echo ""
    echo -e "${GREEN}✓ DKIM record added to Cloudflare DNS!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Wait 5-15 minutes for DNS propagation"
    echo "2. Verify: ./verify-email-auth.sh ${DOMAIN}"
    echo "3. In Google Admin Console, enable DKIM authentication"
else
    echo ""
    echo -e "${RED}✗ Failed to add DKIM record to Cloudflare${NC}"
    echo ""
    echo "You can add it manually:"
    echo "Selector: ${SELECTOR}"
    echo "Record name: ${SELECTOR}._domainkey.${DOMAIN}"
    echo "TXT Record: ${DKIM_TXT}"
    exit 1
fi

