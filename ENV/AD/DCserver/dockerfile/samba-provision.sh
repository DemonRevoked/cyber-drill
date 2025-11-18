#!/bin/bash

set -e

# Call the vars script
SCRIPT_PATH=$(dirname "$0")
source "$SCRIPT_PATH"/vars.sh

if [ -f "$CONFIG_FILE" ]; then
    echo "Samba config file found at: $CONFIG_FILE"
    echo "Samba seems to be provisioned already. Exiting."
    exit 1
fi

# Ensure ADMIN_PASSWORD is set (required for automation)
if [ -z "$ADMIN_PASSWORD" ]; then
    echo "ERROR: ADMIN_PASSWORD environment variable is required for provisioning."
    exit 1
fi
echo "Using ADMIN_PASSWORD for provisioning (length: ${#ADMIN_PASSWORD} chars)."

# Define DOMAIN_NETBIOS if not set (fallback to uppercase of first part of DOMAIN_FQDN)
if [ -z "$DOMAIN_NETBIOS" ]; then
    DOMAIN_NETBIOS=$(echo "${DOMAIN_FQDN}" | cut -d'.' -f1 | tr '[:lower:]' '[:upper:]')
fi

# Provision a new AD domain non-interactively
samba-tool domain provision \
    --use-rfc2307 \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --realm="${DOMAIN_FQDN_UCASE:-$(echo "${DOMAIN_FQDN}" | tr '[:lower:]' '[:upper:]')}" \
    --domain="${DOMAIN_NETBIOS}" \
    --host-name="${DC_NAME:-dc1}" \
    --host-ip="${DC_IP}" \
    --adminpass="$ADMIN_PASSWORD"

echo "Domain provisioning complete."

# Explicitly set Administrator password (ensures it's applied post-provision)
samba-tool user setpassword Administrator --newpassword="$ADMIN_PASSWORD"
echo "Administrator password set."

# Disable password expiry, etc.
samba-tool domain passwordsettings set --history-length=0
samba-tool domain passwordsettings set --min-pwd-age=0
samba-tool domain passwordsettings set --max-pwd-age=0

# smb.conf: replace the default DNS forwarder (127.0.0.11) with our main DNS server IP address
sed -i "/dns forwarder/c\    dns forwarder = ${DNSFORWARDER}" "$DEFAULT_CONFIG_FILE"

# smb.conf: disable NetBIOS
sed -i "/\[global\]/a \    disable netbios = yes" "$DEFAULT_CONFIG_FILE"

# smb.conf: move the config created by the provisioning tool to our target directory
mv "$DEFAULT_CONFIG_FILE" "$CONFIG_FILE"

echo "Samba provisioning successful. Config moved to $CONFIG_FILE."
