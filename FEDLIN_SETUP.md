# DNS Setup Guide for fedlin.com

## Current Status
- **Email Provider:** Google Workspace
- **DNS Provider:** Cloudflare
- **Migration:** From Dreamhost to Cloudflare

## Required DNS Records

### 1. SPF Record (Update Required)
**Current:** Contains Dreamhost references that need to be removed

**Action:** Update the TXT record at root domain

**Record Type:** TXT  
**Name:** `@` (or `fedlin.com`)  
**Content:** `v=spf1 include:_spf.google.com ~all`  
**TTL:** Auto

**Note:** Remove `include:netblocks.dreamhost.com` and `include:relay.mailchannels.net` if no longer needed.

---

### 2. DKIM Record (Add Required)
**Status:** Missing - this is likely causing email sending issues

**Action:** Get DKIM record from Google Workspace and add to Cloudflare DNS

#### Steps to get DKIM from Google Workspace:
1. Go to [Google Admin Console](https://admin.google.com)
2. Navigate to: **Apps** → **Google Workspace** → **Gmail**
3. Scroll to **Authenticate email** section
4. Click **Show authentication record** or **Generate new record**
5. You'll see:
   - **Selector:** Usually `google` (or another value)
   - **TXT record value:** A long string starting with `v=DKIM1; k=rsa; p=...`

#### Add to Cloudflare DNS:
**Record Type:** TXT  
**Name:** `google._domainkey` (replace `google` with your actual selector if different)  
**Content:** [Paste the full TXT record value from Google]  
**TTL:** Auto

**Example:**
```
Name: google._domainkey
Content: v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC...
```

---

### 3. DMARC Record (Already Configured ✓)
**Status:** Already present and correctly configured

**Current Record:**
```
Name: _dmarc
Content: v=DMARC1; p=none; pct=100; rua=mailto:dmarc@fedlin.com; ruf=mailto:dmarc@fedlin.com; fo=1
```

No action needed.

---

## Verification

After adding/updating records:

1. **Wait for DNS propagation** (usually 5-15 minutes, can take up to 48 hours)

2. **Run verification script:**
   ```bash
   ./verify-email-auth.sh fedlin.com
   ```

3. **Or use the GitHub Actions workflow:**
   - Go to Actions tab
   - Run "dmarc-spf-dkim-dns-check" workflow
   - Enter domain: `fedlin.com`

4. **Test email sending:**
   - Send a test email from info@fedlin.com
   - Check email headers for:
     - `Authentication-Results` header showing SPF/DKIM/DMARC pass
     - `DKIM-Signature` header present

5. **Online verification tools:**
   - [MXToolbox Email Health](https://mxtoolbox.com/emailhealth/)
   - [Google Admin Toolbox](https://toolbox.googleapps.com/apps/checkmx/check)
   - [Mail Tester](https://www.mail-tester.com/)

---

## Expected Final Configuration

### SPF
```
fedlin.com. TXT "v=spf1 include:_spf.google.com ~all"
```

### DKIM
```
google._domainkey.fedlin.com. TXT "v=DKIM1; k=rsa; p=[PUBLIC_KEY]"
```

### DMARC
```
_dmarc.fedlin.com. TXT "v=DMARC1; p=none; pct=100; rua=mailto:dmarc@fedlin.com; ruf=mailto:dmarc@fedlin.com; fo=1"
```

---

## Troubleshooting

### DKIM not found after adding
- Verify selector name matches exactly (case-sensitive)
- Ensure full TXT record value was copied (can be very long)
- Wait for DNS propagation (check with `dig google._domainkey.fedlin.com TXT`)
- Verify record was added to Cloudflare DNS (not Dreamhost DNS)

### Emails still failing authentication
- Check SPF includes Google Workspace (`include:_spf.google.com`)
- Verify DKIM selector matches what Google shows
- Ensure DMARC policy allows emails (`p=none` is safe for testing)
- Check email headers for specific failure reasons

### DNS propagation delays
- Cloudflare DNS typically propagates quickly (5-15 minutes)
- Use `dig` command to check specific records
- Different DNS servers may cache old records

---

## Quick Reference Commands

```bash
# Check SPF
dig +short fedlin.com TXT | grep spf

# Check DMARC
dig +short _dmarc.fedlin.com TXT

# Check DKIM
dig +short google._domainkey.fedlin.com TXT

# Check MX records
dig +short fedlin.com MX

# Run full verification
./verify-email-auth.sh fedlin.com
```

