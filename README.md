# Linux Security Hardening Lab

YH Program: Linux, Unix and Mac Security | Ubuntu Server 24.04

---

## Overview

This repository documents a hands-on security lab focused on building a web server from scratch and systematically hardening it against **CIS Benchmark Level 1** using OpenSCAP as the measurement tool.

The lab was divided into four parts:

1. Web server setup with WordPress, MariaDB and SSL
2. Manual hardening (5 CIS controls)
3. Automated hardening via OpenSCAP remediation script
4. LDAP directory with automated user import

---

## Part 1 — Web Server (WordPress + MariaDB + UFW + SSL)

**Stack:** Ubuntu Server 24.04, Apache2, MariaDB, PHP 8.3, WordPress 6.9

- Created a dedicated database user with limited privileges
- Configured UFW with minimum necessary rules (port 22, 80, 443)
- SSL via ngrok tunnel with dynamic URL handling in `wp-config.php`
- File permissions set with `chown -R www-data:www-data`

---

## Part 2 — Manual Hardening (CIS Benchmark Level 1)

**Tools:** OpenSCAP, SCAP Security Guide 0.1.78  
**Profile:** `xccdf_org.ssgproject.content_profile_cis_level1_server`

Baseline scan before hardening: **68.25% compliance (235 pass / 105 fail)**

### Implemented controls

| # | Control | Severity | File(s) |
|---|---------|----------|---------|
| 1 | Disable SSH root login | High | `/etc/ssh/sshd_config` |
| 2 | Account lockout via pam_faillock | Medium | `/etc/security/faillock.conf`, `/etc/pam.d/common-auth` |
| 3 | SSH idle session timeout | Medium | `/etc/ssh/sshd_config` |
| 4 | Set default umask to 027 | Medium | `/etc/login.defs`, `/etc/profile`, `/etc/bash.bashrc` |
| 5 | AppArmor in enforce mode | Medium | `/etc/apparmor.d/*` |

Scan after manual hardening: **70.23% compliance (242 pass / 98 fail)**

### Methodology

Each control followed the same pattern:
1. Verify current configuration
2. Back up the configuration file
3. Edit and save
4. Validate syntax (e.g. `sudo sshd -t` for SSH changes)
5. Restart service and verify

---

## Part 3 — Automated Hardening

OpenSCAP can generate a Bash script directly from a security profile that automatically remediates the majority of vulnerabilities:

```bash
sudo oscap xccdf generate fix \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --fix-type bash \
  ~/scap-content/scap-security-guide-0.1.78/ssg-ubuntu2404-ds.xml \
  > ~/cis_remediation.sh
```

The script took 10–15 minutes to run and automatically remediated over 100 rules.

Scan after automated hardening: **91.6% compliance (323 pass / 27 fail)**

> The remaining 27 rules require manual configuration and contextual judgment — something a script can never fully replace.

---

## Part 4 — OpenLDAP with Automated User Import

**Environment:** Separate Ubuntu Server VM, domain `hector.local`

- Installed and configured OpenLDAP (`slapd`)
- Created organizational structure with OUs for `users` and `groups`
- Added test users manually via LDIF files
- Verified cross-server communication using `ldapsearch`

### import_users.sh

A Bash script for bulk importing users from a CSV file into the LDAP directory. The script handles password hashing via `slappasswd` and dynamically generates LDIF entries for each row in the CSV.

**CSV format:**
```
uid,givenName,sn,uidNumber,password
linus,Linus,Torvalds,10002,Password123
```

See `scripts/import_users.sh` for the full script.

---

## Compliance progression

| Phase | Pass | Fail | Score |
|-------|------|------|-------|
| Baseline | 235 | 105 | 68.25% |
| After manual hardening | 242 | 98 | 70.23% |
| After automated hardening | 323 | 27 | 91.6% |

---

## Tools and technologies

- OpenSCAP / SCAP Security Guide
- CIS Benchmark Level 1 (Ubuntu 24.04)
- UFW, SSH, PAM, AppArmor
- OpenLDAP (slapd), ldap-utils
- Apache2, MariaDB, PHP, WordPress
- Bash scripting
- Hyper-V (snapshots for restore points)
