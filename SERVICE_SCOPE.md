# Service Scope — DMARC / SPF / DKIM

## In scope
- Up to 2 sending domains
- SPF for Microsoft 365 or Google Workspace
- DKIM enablement notes
- DMARC record with reporting (rua) to customer-controlled mailbox/service
- Documentation for audit/MSP handoff

## Out of scope
- Ongoing DMARC report/forensic analysis
- Complex multi-sender mapping (marketing platforms, ticketing, billing)
- BIMI, MTA-STS, TLS-RPT
- Taking ownership of DNS

## Optional add-ons
- Additional domains/senders
- Third-party sender mapping (e.g. SendGrid, HubSpot)
- CI-based DNS validation using GitHub Actions (OIDC)
