#!/bin/bash
set -e

# Load vars.sh
source /usr/helpers/vars.sh

# Wait for DC to be ready (poll LDAP port 389 on DC_IP)
echo "Waiting for DC at ${DC_IP}:389..."
timeout=300  # 5 min max wait
while ! nc -z "${DC_IP}" 389; do
    if [ $timeout -le 0 ]; then
        echo "ERROR: DC not ready after timeout."
        exit 1
    fi
    echo "DC not ready, waiting 5s... (remaining: ${timeout}s)"
    sleep 5
    timeout=$((timeout - 5))
done
echo "DC is ready."

# Check if already joined (via presence of our config file)
if [ ! -f /etc/samba/config/smb.conf ]; then
    echo "Auto-joining domain..."
    if [ -z "$ADMIN_PASSWORD" ]; then
        echo "ERROR: ADMIN_PASSWORD environment variable required for auto-join."
        exit 1
    fi
    # Run join script non-interactively
    echo "$ADMIN_PASSWORD" | /usr/helpers/samba-join.sh --password-stdin
    # Or manual fallback: echo "$ADMIN_PASSWORD" | realm join -U Administrator ${DOMAIN_FQDN}
    # Generate keytab if not present
    if [ ! -f /etc/krb5.keytab ]; then
        echo "$ADMIN_PASSWORD" | net ads keytab create -U Administrator
        chmod 600 /etc/krb5.keytab
    fi
    # Restart services
    service smbd restart || systemctl restart smbd
    service winbind restart || systemctl restart winbind
    echo "Domain join complete."
else
    echo "Already joined to domain, skipping."
fi

# Run the original init-fs.sh to start services
exec /usr/helpers/init-fs.sh "$@"
