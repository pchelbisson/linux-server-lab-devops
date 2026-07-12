A beginner-friendly DevOps lab project: Linux server setup, security hardening, SSH keys, firewall, fail2ban, Nginx static site, backup script.

# Linux Server Setup \& Hardening — Lab Project

A DevOps tutorial project covering basic Linux server setup, secure SSH access, network rules, Nginx, and backups.

## What I did in this project

### 1. Installed and performed basic Linux configuration (Ubuntu 20.04)

- Installed Ubuntu Server in VirtualBox

- Configured a devops user

- Updated packages and performed basic system preparation



### 2. Configuring SSH with keys
---

- Enabled SSH key access

- Disabled password login (increased security)

- Disabled root login

- Forwarded a port through VirtualBox for connections from the host

### 3. Firewall Settings (UFW)
---

- Open only secure ports:
  - 22 (SSH)
  - 80 (HTTP)
- Everything else is blocked.

### 4. Installing and Configuring Fail2Ban
---

- Enabled SSH protection

- Configured maxretry, bantime, and findtime

- Protection against brute-force attacks

### 5. Installing Nginx
---

- Installed Nginx

- Configured a simple static page (web/index.html)

- Tested the web server from the browser
 
### 6. Backup Script
--- 
I created my own bash script, backup.sh, which:

- archives server configuration files
- saves them to /home/devops/backup/
- runs automatically via cron once a day
- auto-remove archives older than 7 days

## Project structure

```text
linux-server-lab-devops/
├── backup/
│   └── backup.sh
├── configs/
│   ├── jail.local.example
│   ├── nginx.conf.example
│   └── sshd_config.example
├── docs/
│   ├── architecture_diagram.png
│   └── backup_pic.png
├── web/
│   └── index.html
└── README.md
```
---

## Design decisions

### Nginx Configuration
* **`X-Frame-Options: SAMEORIGIN`** - prevents attackers from covertly embedding our site into third-party web pages, while preserving the functionality of internal iframe widgets.

* **`X-Content-Type-Options: nosniff`** - prevents the browser from executing files (such as user-uploaded images) as executable code or scripts if their actual content differs from the type declared by the server.

* **`X-XSS-Protection`** - It is considered outdated and insecure, so I decided not to use it. `CSP` decided not to use it, relying on other headers for now.

### SSH Configuration
* **`AllowUsers devops`** - Restricts SSH login to a single, explicit account rather than any user with a valid key or password. This narrows the attack surface: even if another system account's credentials were ever exposed, SSH access would still be blocked for it. Using an explicit username instead of a group avoids relying on group membership as an implicit trust boundary — the allowed accounts are visible directly in the config, not inferred from `/etc/group`.
* **Why not fail2ban alone** - Using only one leaves a gap: without `AllowUsers`, a leaked key grants instant access; without `fail2ban`, botnets can continuously flood the SSH port, causing log pollution and potential denial of service (DoS). Together, they form a robust proactive and reactive defense system.

## Skills I've honed 

* Linux administration
* SSH hardening 
* Firewall configuration (UFW)
* Fail2Ban security
* Nginx setup
* Bash scripting
* Cron automation
* Working with Git and GitHub

### Contacts
---
 
If you'd like to discuss the project or provide feedback, I'd be happy to hear from you!
https://www.linkedin.com/in/andrew-lagutin-259051221/




