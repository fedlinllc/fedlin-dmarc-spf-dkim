# How to Get DKIM Key from Google Workspace

## Step-by-Step Instructions

### 1. Access Google Admin Console

1. Go to: https://admin.google.com
2. Sign in with your admin account

### 2. Navigate to DKIM Settings

1. Click **Apps** (left sidebar)
2. Click **Google Workspace**
3. Click **Gmail**
4. Scroll down to **Authenticate email** section
5. Click **Authenticate email**

### 3. Generate or View DKIM Record

**Option A: If DKIM is already enabled:**
- Click **"Show authentication record"** or **"View authentication record"**
- You'll see:
  - **Selector name** (usually `google`)
  - **TXT record value** (starts with `v=DKIM1; k=rsa; p=...`)

**Option B: If DKIM needs to be generated:**
- Click **"Generate new record"** or **"Start authentication"**
- Select a selector name (default is usually `google`)
- Click **Generate**
- Copy the **TXT record value**

### 4. Copy the Information

You need:
- **Selector name**: Usually `google` (or whatever selector you chose)
- **Full TXT record value**: The complete string starting with `v=DKIM1`

Example:
```
Selector: google
TXT Record: v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC...
```

### 5. Add via API

Once you have the selector and TXT record value:

```bash
# Set Cloudflare API credentials first
export CLOUDFLARE_API_TOKEN="your-token"

# Add DKIM record
./add-dkim.sh google "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY_HERE"
```

Or use the interactive script:
```bash
./add-dkim.sh
# It will prompt you for selector and content
```

### 6. Verify

After adding, verify the record:

```bash
./verify-email-auth.sh fedlin.com
```

Or check manually:
```bash
dig +short google._domainkey.fedlin.com TXT
```

## Troubleshooting

### Can't find "Authenticate email" option
- Make sure you're signed in as a Super Admin
- The option may be under: **Apps** → **Google Workspace** → **Settings for Gmail** → **User settings** → **Authenticate email**

### DKIM shows as "Not authenticated"
- After adding the DNS record, wait 5-15 minutes
- Go back to Google Admin Console and click **"Start authentication"** or **"Authenticate"**
- Google will verify the DNS record and enable DKIM

### Selector name is different
- Use whatever selector name Google shows (could be `default`, `s1`, `s2`, etc.)
- The DNS record name will be: `<selector>._domainkey.fedlin.com`

