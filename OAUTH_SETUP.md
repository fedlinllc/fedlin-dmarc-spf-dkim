# OAuth Setup for Google Workspace Admin API

## Overview

OAuth is simpler than service accounts - no need to create service accounts, download JSON files, or set up domain-wide delegation. Just authenticate with your Google account.

## Quick Setup

### Step 1: Run OAuth Setup Script

```bash
./oauth-setup.sh
```

This will:
1. Authenticate with Google Cloud (OAuth)
2. Set up application-default credentials (OAuth)
3. Configure your GCP project

### Step 2: Use the Scripts

Once OAuth is set up, you can run:

```bash
# Set Cloudflare token
export CLOUDFLARE_API_TOKEN="your-token"

# Run DKIM setup
./google-workspace-dkim.sh fedlin.com
```

## Manual OAuth Setup

If you prefer to set up manually:

```bash
# 1. Authenticate with Google Cloud
gcloud auth login

# 2. Set up application-default credentials
gcloud auth application-default login

# 3. Set your Fedlin project
gcloud config set project YOUR-FEDLIN-PROJECT-ID

# 4. Verify
gcloud auth application-default print-access-token
```

## How OAuth Works

1. **`gcloud auth login`** - Authenticates your Google account with gcloud
2. **`gcloud auth application-default login`** - Sets up OAuth credentials that applications can use
3. Scripts use these OAuth credentials to access Google Workspace Admin API

## Advantages of OAuth

- ✅ No service account setup needed
- ✅ No JSON files to manage
- ✅ No domain-wide delegation configuration
- ✅ Uses your existing Google account
- ✅ Easier to set up and maintain

## Troubleshooting

### "Application-default credentials not found"
Run: `gcloud auth application-default login`

### "Insufficient permissions"
Make sure your Google account has Google Workspace Admin privileges.

### "Project not found"
Set the correct project:
```bash
gcloud config set project YOUR-FEDLIN-PROJECT-ID
```

## Token Refresh

OAuth tokens automatically refresh. If you get authentication errors:
```bash
gcloud auth application-default login
```

## Comparison: OAuth vs Service Account

| Feature | OAuth | Service Account |
|---------|-------|-----------------|
| Setup Complexity | Simple | Complex |
| Requires JSON File | No | Yes |
| Domain Delegation | No | Yes |
| Best For | Interactive use | Automation/CI |

For this use case (setting up DKIM), OAuth is recommended.

