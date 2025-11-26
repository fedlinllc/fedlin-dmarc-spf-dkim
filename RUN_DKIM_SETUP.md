# Running DKIM Setup with Existing GCP Connection

## Current Status

You're connected to GCP (project: `slplab-app`), but we need to set up application-default credentials for the Google Workspace Admin API.

## Quick Setup

### Step 1: Set up Application Default Credentials

Since you're already authenticated with gcloud, run:

```bash
gcloud auth application-default login
```

This will open a browser for authentication. After completing, the credentials will be cached.

### Step 2: Run the DKIM Script

Once application-default credentials are set:

```bash
# Set Cloudflare API token
export CLOUDFLARE_API_TOKEN="your-cloudflare-token"

# Run the script
./google-workspace-dkim.sh fedlin.com
```

Or if you prefer the Python version (requires installing libraries):

```bash
# Install Python libraries (if needed)
pip3 install --user google-auth google-api-python-client

# Run Python script
export CLOUDFLARE_API_TOKEN="your-cloudflare-token"
python3 google_dkim.py
```

## What the Script Does

1. **Authenticates** with Google Workspace Admin API using your gcloud credentials
2. **Checks** for existing DKIM keys for `fedlin.com`
3. **Generates** a new DKIM key if needed (selector: `google`)
4. **Adds** the DKIM TXT record to Cloudflare DNS via API
5. **Verifies** the record was added

## Alternative: Manual Steps

If you prefer to do it manually:

1. **Get DKIM from Google Admin Console:**
   - https://admin.google.com
   - Apps → Google Workspace → Gmail → Authenticate email
   - Copy selector and TXT record value

2. **Add to Cloudflare via API:**
   ```bash
   export CLOUDFLARE_API_TOKEN="your-token"
   ./cloudflare-dns.sh fedlin.com add-dkim google "v=DKIM1; k=rsa; p=..."
   ```

## Troubleshooting

### "Application-default credentials not found"
Run: `gcloud auth application-default login`

### "Insufficient permissions"
Make sure your account has Google Workspace Admin privileges and the Admin SDK API is enabled.

### "Domain not found"
Verify `fedlin.com` is added to your Google Workspace account.

## Next Steps After Setup

1. Wait 5-15 minutes for DNS propagation
2. Verify: `./verify-email-auth.sh fedlin.com`
3. In Google Admin Console, enable DKIM authentication
4. Send a test email and check headers

