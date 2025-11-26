# FEDLIN – DMARC / SPF / DKIM

**Security Solutions Architecture · Vulnerability Management · Compliance Automation**

A customer-tenant-first email authentication service to get domains aligned to DMARC, SPF, and DKIM without exposing customer DNS, tenant names, or mail routing in the public repo. Designed for healthcare, professional services, and MSPs that need to harden mail but keep records in their own DNS.

## What this service does
- Identifies your active sending domains
- Defines SPF aligned to your mail platform (M365 or GWS)
- Enables/documents DKIM
- Rolls out DMARC in a safe progression (none → monitor → quarantine → reject)
- Leaves documentation in **your** environment for MSPs and auditors

## What's in this repo
- \`SERVICE_SCOPE.md\` — in/out of scope
- \`RECORD_TEMPLATES.md\` — public-safe DNS examples
- \`EVIDENCE_MODEL.md\` — what to keep and where
- \`DELIVERY_MODEL.md\` — engagement flow (incl. CI/OIDC option)
- \`SECURITY.md\`
- **Automation scripts** — DNS checking, Cloudflare API management, Google Workspace DKIM setup
- **Documentation** — Setup guides for Cloudflare API, Google Workspace API, OAuth configuration

## What's **not** in this repo
- Your actual domains or selectors
- Real DNS zone exports
- Ongoing DMARC report triage

---

## Who this is for

- Organizations that send business or clinical email from custom domains
- MSPs / MSSPs standardizing email auth across multiple customer tenants
- Regulated / PHI-adjacent orgs that must retain control of their DNS
- Subcontract/C2C work where the prime holds the customer relationship

---

## What it delivers

- DMARC policy design and rollout (p=none → quarantine → reject)
- SPF review and consolidation
- DKIM enablement/rotation guidance
- Reporting/forensic setup options that stay in **customer** infrastructure
- GitHub Actions (OIDC-only) delivery patterns for repeatable changes
- Compliance mappings for SOC 2, ISO 27001, HIPAA, NIST (CSF/800-53), PCI DSS, NERC CIP, FERC, FedRAMP, GDPR, CMMC, and other industry frameworks

> **Public repo policy:** This repository describes the service and delivery pattern. It does **not** contain real customer domains, DNS zones, or TXT records. All examples will use placeholders (e.g. `example.com`, `mail.example.com`).

---

## Evidence model (customer-owned)

- DNS changes are applied in **the customer's DNS / tenant**
- Evidence of correct policy is collected from customer-side tooling
- FEDLIN can supply automation via **GitHub Actions with OIDC only**
- Keeps MSP / subcontract deliveries clean for SOC 2, ISO 27001, HIPAA, NIST (CSF/800-53), PCI DSS, NERC CIP, FERC, FedRAMP, GDPR, CMMC, and other industry framework auditors and customers

---

## Delivery method

- **Primary:** GitHub Actions with OIDC-only
- **Options:** Terraform / policy-as-code / bash / python where DNS APIs are available
- **Engagement model:** Independent / C2C, subcontract-ready, MSP-friendly

---

## Deployment assets

Deployment assets (per-domain runbooks, DNS API configs, workflow files, redacted customer notes) are kept in a **private FEDLIN deployment repository** and are provided only as part of an engagement.

This public repo tracks the service description, not the customer code.

---

## Related services

- FEDLIN – Microsoft 365 Security Baseline (`fedlin-m365-security-baseline`)
- FEDLIN – Google Workspace HIPAA Baseline (`fedlin-gws-hipaa-baseline`)
- FEDLIN – AWS Security Baseline (`fedlin-aws-security-baseline`)
- FEDLIN – AWS VistaSec / CMC (`fedlin-aws-vistasec-cmc`)

---

## About FEDLIN

**FEDLIN** delivers:  
**Security Solutions Architecture · Vulnerability Management · Compliance Automation**

Independent / C2C · Subcontract-ready · Customer-tenant-first
