# Security Policy

Thank you for helping keep verify-16k-page-align and its users safe.

## Supported versions

We actively support the latest published version of verify-16k-page-align with security updates. Given the nature of this tool (shell script for analyzing Android APK/AAB/APEX files), security vulnerabilities are primarily related to file processing and command injection.

| Version        | Supported                        |
| -------------- | -------------------------------- |
| Latest release | :white_check_mark:               |
| Older releases | :grey_question: Best-effort only |

## Reporting a vulnerability

Please do not open public GitHub issues for security vulnerabilities.

- Submit a private report via GitHub Security Advisories: https://github.com/hotbrainstech/verify-16k-page-align/security/advisories/new
- If you cannot use advisories, you may open a minimal, non-exploitable issue requesting a security contact, and we will follow up privately.

### What to include

- A description of the issue and potential impact.
- Steps to reproduce or a proof of concept (PoC).
- Sample APK/AAB/APEX files that trigger the issue (if safe to share).
- Affected versions, if known.
- Any suggested mitigations.

**Note**: This tool processes user-provided APK/AAB/APEX files. Please be mindful of potential security issues related to:
- Command injection through malicious file names
- Path traversal vulnerabilities during file extraction
- Resource exhaustion from malformed archives

### Our process and SLAs

- Triage within 2 business days.
- Status updates at least weekly while under investigation.
- If confirmed, we aim to publish a patch or mitigation within 14 days. Complex issues may take longer; we will communicate timelines.
- We credit reporters in release notes if desired and appropriate.

### Safe harbor

We will not pursue legal action for good-faith, non-destructive research that respects the following:

- Do not access, modify, or exfiltrate data you do not own.
- Do not test with malicious APK/AAB/APEX files on systems you do not own.
- Do not attempt to exploit vulnerabilities in production environments.
- Focus testing on the shell script's file processing and validation logic.

Thank you for your responsible disclosure and for helping improve the security of the ecosystem.
