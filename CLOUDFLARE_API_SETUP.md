# Cloudflare API Setup Instructions

## Quick Setup

To use the Cloudflare API scripts, you need to set up authentication. Choose one method:

### Option 1: API Token (Recommended)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Edit zone DNS" template or create custom token with:
   - Permissions: Zone → DNS → Edit
   - Zone Resources: Include → Specific zone → fedlin.com
4. Copy the token

**Set the token:**
```bash
export CLOUDFLARE_API_TOKEN="your-token-here"
```

### Option 2: Global API Key (Less Secure)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Scroll to "API Keys" section
3. Click "View" next to "Global API Key"
4. Copy your email and API key

**Set the credentials:**
```bash
export CLOUDFLARE_EMAIL="your-email@example.com"
export CLOUDFLARE_API_KEY="your-global-api-key"
```

## Using the Scripts

Once credentials are set, you can:

### View current records:
```bash
./cloudflare-dns.sh fedlin.com show
```

### Update SPF record:
```bash
./cloudflare-dns.sh fedlin.com update-spf "v=spf1 include:_spf.google.com ~all"
```

### Add DKIM record:
```bash
./cloudflare-dns.sh fedlin.com add-dkim google "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY_HERE"
```

## GitHub Actions Integration

For CI/CD, add credentials as GitHub Secrets:
- `CLOUDFLARE_API_TOKEN` (preferred), or
- `CLOUDFLARE_API_KEY` and `CLOUDFLARE_EMAIL`

Then use in workflow:
```yaml
env:
  CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

