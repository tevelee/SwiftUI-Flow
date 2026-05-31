# Security policy

## Supported versions

Security fixes are applied to the current `main` branch and the latest tagged release. Older releases are not backported unless the issue is critical.

| Version | Supported |
|---------|-----------|
| `main` (latest) | ✅ |
| Latest `3.x` release | ✅ |
| Older tagged releases | ❌ (upgrade to latest) |

## Reporting a vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report security issues by emailing **tevelee@gmail.com**. Include:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept (if applicable)
- Any suggested mitigations you've identified

**Response timeline:**
- **Acknowledgement** within 7 days
- **Status update** (confirmed / investigating / not reproducible) within 14 days
- **Patch release** within 30 days for confirmed issues, depending on severity

## Disclosure

Once a patch is available, we will:
1. Publish a new release containing the fix
2. Add a security advisory to the repository
3. Credit the reporter (unless they prefer to remain anonymous)

We follow [coordinated disclosure](https://en.wikipedia.org/wiki/Coordinated_vulnerability_disclosure) — please give us time to issue a patch before publishing details publicly.
