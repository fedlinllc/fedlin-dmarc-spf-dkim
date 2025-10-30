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
- \`SERVICE_SCOPE.md\` — in/out of scope
- \`RECORD_TEMPLATES.md\` — public-safe DNS examples
- \`EVIDENCE_MODEL.md\` — what to keep and where
- \`DELIVERY_MODEL.md\` — engagement flow (incl. CI/OIDC option)
- \`SECURITY.md\`

## What’s **not** in this repo
- Your actual domains or selectors
- Real DNS zone exports
- Ongoing DMARC report triage

---

Need us to set this up for you?

📬 info@fedlin.com  
🌐 https://www.fedlin.com
