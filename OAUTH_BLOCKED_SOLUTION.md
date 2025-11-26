# OAuth Blocked - Alternative Solutions

## Problem

Google blocked the OAuth attempt for Admin SDK API access, seeing it as a security risk. This is common when:
- The app isn't verified by Google
- The OAuth request looks suspicious
- Domain-wide delegation isn't properly configured

## Solutions

### Option 1: Manual DKIM Retrieval (Easiest)

Get DKIM from Google Admin Console and add via Cloudflare API:

```bash
./get-dkim-manual.sh fedlin.com
```

This script will:
1. Guide you to get DKIM from Google Admin Console
2. Prompt you to paste the DKIM record
3. Add it to Cloudflare DNS via API (if credentials set)

**Steps:**
1. Go to https://admin.google.com
2. Apps → Google Workspace → Gmail → Authenticate email
3. Select `fedlin.com`
4. Click "Show authentication record" or "Generate new record"
5. Copy selector and TXT record value
6. Run the script and paste when prompted

### Option 2: Service Account (For Automation)

If you need automation, set up a service account:

1. **Create Service Account:**
   - Go to: https://console.cloud.google.com
   - IAM & Admin → Service Accounts → Create Service Account
   - Name it (e.g., "dkim-manager")
   - Grant "Domain Admin" or appropriate role

2. **Create Key:**
   - Click on service account → Keys → Add Key → Create new key → JSON
   - Download the JSON file

3. **Enable Domain-Wide Delegation:**
   - In Google Admin Console: https://admin.google.com
   - Security → API Controls → Domain-wide Delegation
   - Add new → Enter Client ID from JSON
   - OAuth Scopes: `https://www.googleapis.com/auth/admin.directory.domain`
   - Authorize

4. **Use Service Account:**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   export GOOGLE_ADMIN_EMAIL="admin@fedlin.com"  # Your admin email
   ./google-workspace-dkim.sh fedlin.com
   ```

### Option 3: Use Google Admin Console Directly

Just get DKIM manually and add to Cloudflare:

1. **Get DKIM from Google:**
   - Admin Console → Apps → Google Workspace → Gmail → Authenticate email
   - Copy selector (usually `google`) and TXT record

2. **Add to Cloudflare via API:**
   ```bash
   export CLOUDFLARE_API_TOKEN="your-token"
   ./cloudflare-dns.sh fedlin.com add-dkim google "v=DKIM1; k=rsa; p=..."
   ```

## Recommended Approach

For your use case (one-time setup), **Option 1 (Manual)** is simplest:
- No OAuth issues
- No service account setup
- Still uses Cloudflare API for automation
- Takes 2 minutes

## Quick Start

```bash
# Set Cloudflare token
export CLOUDFLARE_API_TOKEN="your-token"

# Run manual script
./get-dkim-manual.sh fedlin.com
```

Follow the prompts - it will guide you through getting DKIM from Google and adding it to Cloudflare.

