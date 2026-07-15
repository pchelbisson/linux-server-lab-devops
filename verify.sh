#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup/backup.sh"

print_status() {
    local service=$1
    local is_failed=$2
    local message=$3
    
    if [ "$is_failed" -eq 0 ]; then
        echo -e "[ ${GREEN}PASS${NC} ] ${service}: ${message}"
        ((PASSED++))
    else
        echo -e "[ ${RED}FAIL${NC} ] ${service}: ${message}"
        ((FAILED++))
    fi
}

echo "=== STARTING TESTS ==="

# Test SSHD configuration

SSH_FAIL=0
SSH_DETAILS=""

# Check if the SSH service is active
SSH_STATUS=$(systemctl is-active sshd 2>/dev/null)
if [ "$SSH_STATUS" = "active" ]; then
    SSH_DETAILS="sshd is active"
else
    SSH_FAIL=1
    SSH_DETAILS="sshd is NOT active"
fi

# Config file check
PASSWORD_AUTH=$(sshd -T 2>/dev/null | grep -i '^passwordauthentication ' | awk '{print $2}')
if [ "$PASSWORD_AUTH" = "no" ]; then
    SSH_DETAILS="${SSH_DETAILS}, password auth disabled"
else
    SSH_FAIL=1
    SSH_DETAILS="${SSH_DETAILS}, password auth ENABLED (expected no)"
fi

print_status "SSH" "$SSH_FAIL" "$SSH_DETAILS"

# Test Fail2Ban configuration

F2B_FAIL=0
F2B_DETAILS=""

# Check if the Fail2Ban service is active
F2B_STATUS=$(systemctl is-active fail2ban 2>/dev/null)
if [ "$F2B_STATUS" = "active" ]; then
    F2B_DETAILS="service is active"
    
    # We survey the client ONLY if the service is actually working.
    if fail2ban-client status sshd >/dev/null 2>&1; then
        F2B_DETAILS="${F2B_DETAILS}, jail 'sshd' is running"
    else
        F2B_FAIL=1
        F2B_DETAILS="${F2B_DETAILS}, jail 'sshd' is NOT running"
    fi
else
    F2B_FAIL=1
    F2B_DETAILS="service is NOT active (cannot check jails)"
fi

print_status "Fail2Ban" "$F2B_FAIL" "$F2B_DETAILS"

# UFW Test

UFW_FAIL=0
UFW_DETAILS=""

UFW_STATUS_RAW=$(ufw status 2>/dev/null)

if echo "$UFW_STATUS_RAW" | grep -q "Status: active"; then
    UFW_DETAILS="status is active"

    # Check ports ONLY if the status is active.
    if echo "$UFW_STATUS_RAW" | grep -Ei '\b22\b' | grep -qi 'ALLOW'; then
        UFW_DETAILS="${UFW_DETAILS}, port 22 is allowed"
    else
        UFW_FAIL=1
        UFW_DETAILS="${UFW_DETAILS}, port 22 is NOT allowed"
    fi

    if echo "$UFW_STATUS_RAW" | grep -Ei '\b80\b' | grep -qi 'ALLOW'; then
        UFW_DETAILS="${UFW_DETAILS}, port 80 is allowed"
    else
        UFW_FAIL=1
        UFW_DETAILS="${UFW_DETAILS}, port 80 is NOT allowed"
    fi
else
    UFW_FAIL=1
    UFW_DETAILS="status is INACTIVE"
fi

print_status "UFW" "$UFW_FAIL" "$UFW_DETAILS"

#NGINX Test

NGINX_FAIL=0
NGINX_DETAILS=""

NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null)

if [ "$NGINX_STATUS" = "active" ]; then
    NGINX_DETAILS="service is active"
    
    HTTP_CODE=$(curl -s -o /dev/null --connect-timeout 2 --max-time 3 -w "%{http_code}" http://localhost:80)

    if [ "$HTTP_CODE" = "200" ]; then
        NGINX_DETAILS="${NGINX_DETAILS}, responding with HTTP 200"
    else
        NGINX_FAIL=1
        if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" = "000" ]; then
            NGINX_DETAILS="${NGINX_DETAILS}, connection TIMEOUT or failed"
        else
            NGINX_DETAILS="${NGINX_DETAILS}, responding with HTTP $HTTP_CODE (expected 200)"
        fi
    fi
else
    NGINX_FAIL=1
    NGINX_DETAILS="service is NOT active, HTTP check skipped"
fi

print_status "Nginx" "$NGINX_FAIL" "$NGINX_DETAILS"

#Cron Test

CRON_FAIL=0
CRON_DETAILS=""

CRON_LIST=$(crontab -l 2>/dev/null)

if echo "$CRON_LIST" | grep -qi "$BACKUP_SCRIPT"; then
    CRON_DETAILS="backup job is present in crontab"
else
    CRON_FAIL=1
    CRON_DETAILS="backup job is MISSING in crontab"
fi

print_status "Backup cron" "$CRON_FAIL" "$CRON_DETAILS"

# FINAL SUMMARY AND EXIT

echo -e "\n=== FINAL SUMMARY ==="
echo "Total tests completed (PASSED): $PASSED"
echo "Total tests failed (FAILED): $FAILED"

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}Status: FAIL (Errors detected!)${NC}"
    exit 1
else
    echo -e "${GREEN}Status: SUCCESS (All tests passed successfully!)${NC}"
    exit 0
fi