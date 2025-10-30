# Delivery Model — DMARC / SPF / DKIM

1. **Discovery** — identify sending domains and mail platform (M365 or GWS).
2. **Draft** — generate SPF, DKIM, and DMARC records appropriate to the platform.
3. **Apply** — customer/MSP applies records to DNS.
4. **Verify** — confirm propagation and platform alignment.
5. **Document** — store final config in the customer environment for audits/MSPs.

**CI / OIDC option**  
For customers using GitHub, we can add a lightweight DNS validation workflow that runs with OIDC (no long-lived secrets) to confirm records have not drifted.
