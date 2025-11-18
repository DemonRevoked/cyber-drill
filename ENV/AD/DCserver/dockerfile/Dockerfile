FROM ubuntu:24.04 AS base

# Silent install
ARG DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && apt-get install -y \
        acl \
        attr \
        samba \
        smbclient \
        ldap-utils \
        krb5-config \
        krb5-user \
        libpam-krb5 \
        winbind \
        libnss-winbind \
        libpam-winbind \
        python3-setproctitle \
        ldb-tools \
        openssl \
        ca-certificates \
        tini \
        supervisor \
        inetutils-ping \
        dnsutils \
        iproute2 \
        nano \
        netcat-openbsd \
        && rm -rf /var/lib/apt/lists/*

# Remove the default smb.conf
RUN rm /etc/samba/smb.conf

# Helper files
RUN mkdir -p /usr/helpers
COPY --chmod=755 vars.sh /usr/helpers/vars.sh

#
# Target stage for DCs
#
FROM base AS dc

COPY --chmod=755 init-dc.sh /usr/helpers/init-dc.sh
COPY --chmod=755 samba-provision.sh /usr/helpers/samba-provision.sh
COPY --chmod=755 entrypoint-dc.sh /usr/local/bin/entrypoint-dc.sh  
# New wrapper for automation

# Set environment for DC
ENV TARGET=dc

# Start via Tini and our automated entrypoint (wraps init-dc.sh)
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/entrypoint-dc.sh"]

#
# Target stage for FSs
#
FROM base AS fs

COPY --chmod=755 init-fs.sh /usr/helpers/init-fs.sh
COPY --chmod=755 samba-join.sh /usr/helpers/samba-join.sh
COPY --chmod=755 entrypoint-fs.sh /usr/local/bin/entrypoint-fs.sh  
# New wrapper for automation
RUN mkdir -p /etc/supervisor/config
COPY --chmod=644 supervisord-fs.conf /etc/supervisor/config/supervisord.conf

# Set environment for FS
ENV TARGET=fs

# Start via Tini and our automated entrypoint (wraps init-fs.sh)
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/entrypoint-fs.sh"]
