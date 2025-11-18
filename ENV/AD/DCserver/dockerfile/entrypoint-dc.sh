#!/bin/bash
set -e

# Main function to avoid global 'local' issues
main() {
    # Source vars.sh only if essential vars are missing (avoids full source if problematic)
    if [ -z "$CONFIG_FILE" ] || [ -z "$DEFAULT_CONFIG_FILE" ]; then
        SCRIPT_PATH="/usr/helpers"
        if [ -f "$SCRIPT_PATH/vars.sh" ]; then
            source "$SCRIPT_PATH/vars.sh" || {
                echo "WARNING: vars.sh sourced with issues; using env fallbacks."
                # Fallback definitions if vars.sh fails
                export CONFIG_FILE="/etc/samba/config/smb.conf"
                export DEFAULT_CONFIG_FILE="/etc/samba/smb.conf"
            }
        else
            echo "vars.sh not found; using fallbacks."
            export CONFIG_FILE="/etc/samba/config/smb.conf"
            export DEFAULT_CONFIG_FILE="/etc/samba/smb.conf"
        fi
    fi

    # Check if already provisioned (smb.conf or AD database exists)
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f /var/lib/samba/private/secrets.tdb ]; then
        echo "Auto-provisioning Samba AD DC..."
        if [ -z "$ADMIN_PASSWORD" ]; then
            echo "ERROR: ADMIN_PASSWORD environment variable required for auto-provisioning."
            exit 1
        fi
        export ADMIN_PASSWORD="$ADMIN_PASSWORD"  # Ensure passed to script
        /usr/helpers/samba-provision.sh
        # Restart services if needed
        service smbd restart || systemctl restart smbd
        service nmbd restart || systemctl restart nmbd || true
        echo "DC provisioning complete."
    else
        echo "DC already provisioned, skipping."
    fi
}

# Run main
main

# Run the original init-dc.sh to start services
exec /usr/helpers/init-dc.sh "$@"
