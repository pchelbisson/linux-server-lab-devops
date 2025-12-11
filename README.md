# linux-server-lab-devops

A beginner-friendly DevOps lab project: Linux server setup, security hardening, SSH keys, firewall, fail2ban, Nginx static site, backup script.



# Linux Server Setup \& Hardening — Lab Project

A DevOps tutorial project covering basic Linux server setup, secure SSH access, network rules, Nginx, and backups.

**📌 What I did in this project**
---

🔐 1. Installed and performed basic Linux configuration (Ubuntu 20.04)



Installed Ubuntu Server in VirtualBox



Configured a devops user



Updated packages and performed basic system preparation



**🔑 2. Configuring SSH with keys**
---

###### 

Enabled SSH key access



Disabled password login (increased security)



Disabled root login



Forwarded a port through VirtualBox for connections from the host

###### 

###### **🔥 3. Firewall Settings (UFW)**

###### 

Open only secure ports:



22 (SSH)



80 (HTTP)



Everything else is blocked.

###### 

###### **🛡 4. Installing and Configuring Fail2Ban**

###### 

Enabled SSH protection



Configured maxretry, bantime, and findtime



Protection against brute-force attacks

###### 

###### **🌐 5. Installing Nginx**

###### 

Installed Nginx



Configured a simple static page (web/index.html)



Tested the web server from the browser

###### 

###### **📦 6. Backup Script**

###### 

I created my own bash script, backup.sh, which:



archives server configuration files



saves them to /home/devops/backup/



runs automatically via cron once a day

###### 

###### **📁 Project structure**



###### linux-server-lab-devops/

###### │

###### ├── backup/

###### │   └── backup.sh

###### │

###### ├── web/

###### │   └── index.html

###### │

###### └── README.md

###### 

###### **🎯 Skills I've honed**

###### 

* Linux administration
* 
* SSH hardening
* 
* Firewall configuration (UFW)
* 
* Fail2Ban security
* 
* Nginx setup
* 
* Bash scripting
* 
* Cron automation
* 
* Working with Git and GitHub

###### 

###### **🚀 Planned Improvements**

###### 

* Add .example backup configs
* 
* Add architecture diagram
* 
* Add fail2ban and nginx configs
* 
* Migrate VMs to the cloud (Oracle Cloud Free Tier)



**📬 Contacts**
---

###### 

If you'd like to discuss the project or provide feedback, I'd be happy to hear from you!
https://www.linkedin.com/in/andrew-lagutin-259051221/




