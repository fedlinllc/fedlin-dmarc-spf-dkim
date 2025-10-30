# Evidence Model (Public-Safe)

| Area    | Evidence                        | Lives in                    | Notes                                    |
|---------|---------------------------------|-----------------------------|------------------------------------------|
| SPF     | DNS TXT export/screenshot       | Customer DNS / shared drive | Proves sender auth is configured         |
| DKIM    | DKIM status in M365 / GWS       | Customer M365/GWS tenant    | Proves DKIM is enabled                    |
| DMARC   | `_dmarc.` TXT export            | Customer DNS / shared drive | Proves DMARC policy and reporting exists |
| CI/Check (opt) | GitHub Actions run       | Customer GitHub             | Proves records stayed compliant           |

> Fedlin does **not** store customer DNS zones or PHI/PII in this public repo.
