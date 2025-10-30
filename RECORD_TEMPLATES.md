# Record Templates (Examples)

> ⚠️ Replace `example.com` with your real domain. These are **examples**, not live records.

## SPF (Microsoft 365)
```txt
example.com. TXT "v=spf1 include:spf.protection.outlook.com -all"

example.com. TXT "v=spf1 include:_spf.google.com -all"

_dmarc.example.com. TXT "v=DMARC1; p=none; rua=mailto:dmarc@example.com"

_dmarc.example.com. TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

selector1._domainkey.example.com. TXT "v=DKIM1; k=rsa; p=BASE64PUBLICKEY"


That gives you a clean markdown file with 5 code blocks.

---

### 2) Add the rest of the files (if you haven’t yet)

Just to be sure, run these too — they’re idempotent; if they already exist they’ll just be overwritten with the correct content.

**README.md**

```bash
cat > README.md <<'EOF'
# FEDLIN — DMARC / SPF / DKIM Setup

**Brand:** Security Architecture · Vulnerability Management · Compliance Automation  
**Delivery stance:** customer-owned DNS/mail, optional CI validation via GitHub Actions (OIDC-only)

We help M365 and Google Workspace organizations get their email authentication aligned (DMARC, SPF, DKIM) so they can pass customer/security reviews — without handing DNS to another vendor.

## What this service does
- Identifies your active sending domains
- Defines SPF aligned to your mail platform (M365 or GWS)
- Enables/documents DKIM
- Rolls out DMARC in a safe progression (none → monitor → quarantine → reject)
- Leaves documentation in **your** environment for MSPs and auditors

## Who it’s for
- M365 / Google Workspace organizations
- Healthcare / professional services that email PHI/PII
- MSPs that want a repeatable, documented setup

## What’s in this repo
- `SERVICE_SCOPE.md`
- `RECORD_TEMPLATES.md`
- `EVIDENCE_MODEL.md`
- `DELIVERY_MODEL.md`
- `SECURITY.md`

## What’s **not** in this repo
- Your actual domains or selectors
- Real DNS zone exports
- Ongoing DMARC report triage

---

Need us to set this up for you?

📬 info@fedlin.com  
🌐 https://www.fedlin.com
