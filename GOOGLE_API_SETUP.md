# Google Workspace Admin API Setup

## Overview

To programmatically get/generate DKIM keys from Google Workspace, you need to authenticate with the Google Admin SDK API.

## Authentication Methods

### Option 1: Service Account (Recommended for Automation)

1. **Create a Service Account:**
   - Go to: https://console.cloud.google.com
   - Select your project (or create one)
   - Navigate: **IAM & Admin** → **Service Accounts**
   - Click **Create Service Account**
   - Name it (e.g., "dkim-manager")
   - Click **Create and Continue**
   - Skip roles for now, click **Done**

2. **Create and Download Key:**
   - Click on the service account you just created
   - Go to **Keys** tab
   - Click **Add Key** → **Create new key**
   - Choose **JSON**
   - Download the key file

3. **Enable Admin SDK API:**
   - Go to: https://console.cloud.google.com/apis/library
   - Search for "Admin SDK API"
   - Click **Enable**

4. **Delegate Domain-Wide Authority:**
   - In Google Admin Console: https://admin.google.com
   - Navigate: **Security** → **API Controls** → **Domain-wide Delegation**
   - Click **Add new**
   - Enter:
     - Client ID: (from service account JSON file, field: `client_id`)
     - OAuth Scopes: `https://www.googleapis.com/auth/admin.directory.domain`
   - Click **Authorize**

5. **Set Environment Variable:**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   ```

### Option 2: OAuth2 Access Token (For Testing)

1. **Create OAuth2 Credentials:**
   - Go to: https://console.cloud.google.com
   - Navigate: **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - Choose **Desktop app**
   - Download the credentials JSON

2. **Get Access Token:**
   ```bash
   # Install Google API client library
   pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
   
   # Use OAuth2 flow to get token
   # Or use gcloud CLI:
   gcloud auth application-default login
   ```

3. **Set Environment Variable:**
   ```bash
   export GOOGLE_ACCESS_TOKEN="your-access-token"
   ```

### Option 3: gcloud CLI (Easiest for Testing)

1. **Install gcloud CLI:**
   ```bash
   # On Linux
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```

2. **Authenticate:**
   ```bash
   gcloud auth application-default login
   ```

3. **Set Project (if needed):**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

## Required API Scopes

The service account or OAuth2 credentials need these scopes:
- `https://www.googleapis.com/auth/admin.directory.domain`

## Customer ID

For most Google Workspace accounts, you can use:
- `my_customer` (default)

Or find your customer ID:
- Go to: https://admin.google.com
- Navigate: **Account** → **Account Settings**
- Customer ID is shown at the top

Set it if different:
```bash
export GOOGLE_CUSTOMER_ID="your-customer-id"
```

## Testing Authentication

Test your setup:
```bash
# If using service account
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# If using gcloud
gcloud auth application-default print-access-token

# Test the script
./google-workspace-dkim.sh fedlin.com
```

## Troubleshooting

### "Insufficient Permission" Error
- Make sure Admin SDK API is enabled
- Verify domain-wide delegation is set up correctly
- Check that the service account has the correct scopes

### "Domain not found" Error
- Verify the domain is added to your Google Workspace account
- Check that you're using the correct customer ID

### "Authentication failed" Error
- Verify credentials file path is correct
- Check that the service account JSON is valid
- Ensure gcloud is authenticated if using that method

## API Endpoints Used

- **Get DKIM Keys:** `GET /admin/directory/v1/customer/{customerId}/domains/{domainName}/dkim`
- **Generate DKIM Key:** `POST /admin/directory/v1/customer/{customerId}/domains/{domainName}/dkim`

## References

- [Google Admin SDK API Documentation](https://developers.google.com/admin-sdk/directory/v1/guides)
- [DKIM API Reference](https://developers.google.com/admin-sdk/directory/v1/reference/domains/dkim)
- [Service Account Setup](https://cloud.google.com/iam/docs/service-accounts)

