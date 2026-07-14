#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# root check
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run the script as root or via sudo." >&2
  exit 1
fi

# SSHD configuration

SRC_SSH="$SCRIPT_DIR/configs/sshd_config.example"
DEST_SSH="/etc/ssh/sshd_config"
SHOULD_RESTART_SSH=false

if ! sshd -t -f "$SRC_SSH" &>/dev/null; then
    echo "CRITICAL ERROR: Template $SRC_SSH contains syntax errors!" >&2
    echo "Copying cancelled to avoid breaking SSH on reboot." >&2
    exit 1
fi

# Check if the destination file exists
if [ -f "$DEST_SSH" ] && cmp -s "$SRC_SSH" "$DEST_SSH"; then
   echo "The SSH configuration is already up to date. No changes required."
else
   SHOULD_RESTART_SSH=true
   # Backup the existing configuration before overwriting   
   if [ -f "$DEST_SSH" ]; then
     BACKUP_SSH="$DEST_SSH.bak.$(date +%s)"
     echo "Changes detected in SSH config. Creating backup: $BACKUP_SSH"
     cp "$DEST_SSH" "$BACKUP_SSH"
   fi
   # If the destination file does not exist, copy the source file
   cp "$SRC_SSH" "$DEST_SSH"
   echo "The SSH configuration has been successfully updated."    
fi

# Fail2Ban configuration

if ! command -v fail2ban-client &> /dev/null; then
  echo "Warning: Fail2ban is not installed on the system. Skipping jail.local configuration." >&2
else
  SRC_F2B="$SCRIPT_DIR/configs/jail.local.example"
  DEST_F2B="/etc/fail2ban/jail.local"

  if [ -f "$DEST_F2B" ] && cmp -s "$SRC_F2B" "$DEST_F2B"; then
    echo "The Fail2ban configuration is already up to date. No changes required."
  else
    # If the file exists and is different — create a backup before replacing
    if [ -f "$DEST_F2B" ]; then
      BACKUP_F2B="$DEST_F2B.bak.$(date +%s)"
      echo "Changes detected in Fail2ban. Creating backup: $BACKUP_F2B"
      cp "$DEST_F2B" "$BACKUP_F2B"
    fi

    cp "$SRC_F2B" "$DEST_F2B"
    echo "The Fail2ban configuration has been successfully updated."

    # Restart the service (sudo is not needed, as the script is already running as root)
    systemctl restart fail2ban
    echo "The Fail2ban service has been successfully restarted."
  fi
fi

# Nginx configuration
# Check if Nginx is installed before proceeding with the configuration
if ! command -v nginx &> /dev/null; then
  echo "Warning: Nginx is not installed on the system. Skipping." >&2
else
  SRC_NGINX="$SCRIPT_DIR/configs/nginx.conf.example"
  DEST_NGINX="/etc/nginx/nginx.conf"

  # Check if the configuration is already up to date
  if [ -f "$DEST_NGINX" ] && cmp -s "$SRC_NGINX" "$DEST_NGINX"; then
    echo "The Nginx configuration is already up to date. No changes required."
  else
    # Create a backup if the old file exists
    if [ -f "$DEST_NGINX" ]; then
      BACKUP_NGINX="$DEST_NGINX.bak.$(date +%s)"
      echo "Changes detected in Nginx. Creating backup: $BACKUP_NGINX"
      cp "$DEST_NGINX" "$BACKUP_NGINX"
    fi

    # Copy the new configuration
    cp "$SRC_NGINX" "$DEST_NGINX"
    echo "The new Nginx configuration has been copied. Checking syntax..."

    # Check syntax before restarting the service
    if nginx -t &> /dev/null; then
      echo "Nginx syntax is correct. Restarting the service..."
      systemctl restart nginx
      echo "The Nginx service has been successfully restarted."
    else
      echo "ERROR: The new Nginx configuration contains syntax errors!" >&2
      echo "Service restart cancelled. Please fix the errors in $DEST_NGINX manually." >&2
      exit 1
    fi
  fi
fi

# UFW configuration

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
  echo "Warning: UFW is not installed on the system. Skipping firewall configuration." >&2
else
  echo "Configuring UFW firewall..."

  # Add allow rules FIRST to prevent lockout
  # Note: UFW is idempotent; running 'allow' on existing rules won't duplicate them.
  ufw allow 22/tcp
  ufw allow 80/tcp

  # Set default policies
  ufw default deny incoming
  ufw default allow outgoing

  # Enable firewall without interactive prompt
  ufw --force enable

  echo "UFW firewall has been successfully configured and enabled."
fi

# Cron job setup for backup script

if ! command -v crontab &> /dev/null; then
  echo "Warning: cron is not installed on the system. Skipping backup job scheduling." >&2
else
  BACKUP_SCRIPT="$SCRIPT_DIR/backup/backup.sh"
  
  # Check if the backup script exists and has execute permissions
  if [ ! -x "$BACKUP_SCRIPT" ]; then
    echo "Setting up permissions for the backup script..."
    chmod +x "$BACKUP_SCRIPT"
  fi

  CRON_JOB="0 0 * * * $BACKUP_SCRIPT >/dev/null 2>&1"

  # Get the existing cron jobs
  EXISTING_CRON="$(crontab -l 2>/dev/null || true)"

  # Check if the backup job is already added
  if echo "$EXISTING_CRON" | grep -Fq "$BACKUP_SCRIPT"; then
    echo "Cron job for backup already exists. Skipping."
  else
    # Merge existing jobs with the new one and load back into crontab
    # Use printf to correctly handle empty crontab and avoid extra newlines
    (echo "$EXISTING_CRON"; echo "$CRON_JOB") | grep -v '^$' | crontab -
    echo "Cron job successfully added: $CRON_JOB"
  fi
fi


# Restart SSHD service 
if [ "$SHOULD_RESTART_SSH" = true ]; then
    systemctl restart sshd
    echo "The SSHD service has been successfully restarted."
fi
