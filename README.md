# 🎯 Cyber Drill - Red vs Blue Training Environment

A comprehensive cyber warfare training platform for conducting controlled Red Team vs Blue Team exercises. This environment includes VPN gateways, Active Directory infrastructure, and intentionally vulnerable applications for realistic training scenarios.

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Deployment Guide](#-deployment-guide)
- [Training Scenarios](#-training-scenarios)
- [Management & Operations](#-management--operations)
- [Troubleshooting](#-troubleshooting)
- [Security Considerations](#-security-considerations)
- [Support & Documentation](#-support--documentation)

---

## 🎯 Overview

Cyber Drill is a containerized training environment designed for authorized cybersecurity training exercises. It simulates a realistic network infrastructure where Red Teams (attackers) and Blue Teams (defenders) can practice their skills in a controlled, isolated environment.

### Key Features

- **🔵 Blue Team Infrastructure**: Secure VPN gateway with access to management and production networks
- **🔴 Red Team Infrastructure**: VPN gateway with limited production network access
- **🏢 Active Directory Environment**: Full Samba AD domain controller with file server
- **🎯 Training Targets**: Intentionally vulnerable web applications for practice
- **📊 LDAP Management**: Web-based LDAP administration interface
- **🌐 Network Isolation**: Separate networks for management, production, and AD services

### ⚠️ Important Notice

**This is a training environment only.** All content is for authorized training use. Activities should be conducted against pre-provisioned lab replicas, synthetic data, or public sources only. No real systems, no credential harvesting, no destructive actions. Controllers maintain a live kill-switch.

---

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10 or later
- Docker Compose 2.0 or later
- Linux host with kernel support for macvlan networksdemon
- Minimum 8GB RAM, 50GB disk space
- Network interface name for macvlan (typically `eth0` or `ens33`)

### One-Command Deployment

```bash
# 1. Clone the repository
git clone <repository-url>
cd cyber-drill

# 2. Configure Active Directory (create .env file)
cd ENV/AD/DCserver
cat > .env << EOF
DOMAIN_FQDN=cyberrange.local
DOMAIN_DN=DC=cyberrange,DC=local
DC_NAME=dc1
FS_NAME=fs1
DC_IP=192.168.1.100
FS_IP=192.168.1.101
LDAPADMIN_IP=192.168.1.102
MAIN_DNS_IP=8.8.8.8
HOST_INTERFACE=eth0
SUBNET=192.168.1.0/24
GATEWAY=192.168.1.1
CONTAINER_IP_RANGE=192.168.1.100/29
ADMIN_PASSWORD=YourSecurePassword123!
EOF

# 3. Deploy all services
cd ../../..
docker-compose up -d

# 4. Verify deployment
docker-compose ps
```

### Access Points

After deployment, access the following services:

- **Blue Team VPN Admin**: `https://<host-ip>:943/admin` (check logs for exact port)
- **Red Team VPN Admin**: `https://<host-ip>:943/admin` (check logs for exact port)
- **Vulnerable Web App**: `http://<host-ip>:5000` (admin/admin123)
- **LDAP Admin**: `https://<host-ip>:6443`

---

## 🏗️ Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Cyber Drill Environment                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐         ┌──────────────┐                   │
│  │ Blue Team    │         │ Red Team    │                   │
│  │ VPN Gateway  │         │ VPN Gateway │                   │
│  │ (1195/udp)   │         │ (1194/udp)  │                   │
│  └──────┬───────┘         └──────┬───────┘                   │
│         │                       │                            │
│         └───────────┬───────────┘                           │
│                     │                                        │
│         ┌───────────▼───────────┐                          │
│         │  Production Network    │                          │
│         │  (10.10.40.0/24)      │                          │
│         └───────────┬───────────┘                          │
│                     │                                        │
│    ┌────────────────┼────────────────┐                     │
│    │                │                │                      │
│ ┌──▼──┐      ┌──────▼──────┐   ┌───▼────┐                 │
│ │ DC1 │      │ Web Server  │   │  FS1   │                 │
│ │ AD  │      │ (Vulnerable) │   │ File   │                 │
│ └──┬──┘      └─────────────┘   │ Server │                 │
│    │                            └────────┘                 │
│    │                                                         │
│ ┌──▼──────────┐                                             │
│ │ phpLDAPadmin│                                             │
│ └─────────────┘                                             │
│                                                               │
│  ┌─────────────────────────────────────┐                    │
│  │  Management Network (10.10.30.0/24) │                    │
│  │  (Blue Team Only)                   │                    │
│  └─────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

### Services

#### BLUE Team Services
- **blue_land_secure_gateway**: OpenVPN Access Server
  - Port: `1195/udp`
  - Networks: `blue_land_management`, `blue_land_production`
  - VPN subnet: `10.10.20.0/24`

#### RED Team Services
- **red_land_vpn_gateway**: OpenVPN Access Server
  - Port: `1194/udp`
  - Network: `blue_land_production` (limited access)
  - VPN subnet: `10.10.10.0/24`

#### ENV Infrastructure Services
- **dc1**: Active Directory Domain Controller (Samba AD)
  - Domain services, DNS, and authentication
  - Networks: `sambanet` (macvlan) and `blue_land_production`
  
- **fs1**: File Server (Samba member server)
  - SMB/CIFS file shares
  - Networks: `sambanet` (macvlan) and `blue_land_production`
  - Depends on: `dc1`

- **phpldapadmin**: LDAP Administration Interface
  - Port: `6443/tcp` (HTTPS)
  - Web-based LDAP management
  - Depends on: `dc1`

- **vulnerable_webserver**: Training target web application
  - Port: `5000/tcp`
  - Contains intentional vulnerabilities for training
  - Network: `blue_land_production`

### Network Architecture

1. **blue_land_management** (`10.10.30.0/24`)
   - Isolated network for Blue Team management operations
   - Only accessible via Blue Team VPN

2. **blue_land_production** (`10.10.40.0/24`)
   - Shared production network
   - Accessible by both Blue and Red teams
   - Contains training targets and infrastructure

3. **sambanet** (macvlan, configurable subnet)
   - Active Directory network with static IPs
   - Uses macvlan driver for direct host network access
   - Required for proper AD DNS and domain services

---

## 📦 Deployment Guide

### Master Deployment (Recommended)

The master `docker-compose.yml` orchestrates all components:

```bash
# From project root
docker-compose up -d
```

### Individual Component Deployment

#### Deploy BLUE Team VPN Only
```bash
cd BLUE
docker-compose -f vpn-compose.yml up -d
```

#### Deploy RED Team VPN Only
```bash
cd RED
docker-compose -f vpn-compose.yml up -d
```

#### Deploy Active Directory Infrastructure Only
```bash
cd ENV/AD/DCserver
# Ensure .env file is configured
docker-compose up -d
```

#### Deploy Web Server Only
```bash
cd ENV/AD/WebServer
docker-compose up -d
```

**Note:** Individual deployments require manual network configuration for proper connectivity.

### Environment Configuration

Create a `.env` file in `ENV/AD/DCserver/` with the following variables:

```bash
# Domain Configuration
DOMAIN_FQDN=cyberrange.local
DOMAIN_DN=DC=cyberrange,DC=local
DC_NAME=dc1
FS_NAME=fs1

# Network Configuration
DC_IP=192.168.1.100
FS_IP=192.168.1.101
LDAPADMIN_IP=192.168.1.102
MAIN_DNS_IP=8.8.8.8
HOST_INTERFACE=eth0
SUBNET=192.168.1.0/24
GATEWAY=192.168.1.1
CONTAINER_IP_RANGE=192.168.1.100/29

# Security
ADMIN_PASSWORD=YourSecurePassword123!
```

### Post-Deployment Configuration

#### OpenVPN Access Server Setup

1. **Access Admin Web UI:**
   - Blue Team: `https://<host-ip>:943/admin`
   - Red Team: `https://<host-ip>:943/admin`

2. **Get Initial Credentials:**
   ```bash
   docker logs blue_land_secure_gateway | grep -i password
   ```

3. **Create VPN Users:**
   - Log into admin UI
   - Navigate to User Management
   - Create users and generate client configuration files

#### Active Directory Setup

1. **Verify Domain Controller:**
   ```bash
   docker exec -it dc1 samba-tool domain info cyberrange.local
   ```

2. **Create Domain Users:**
   ```bash
   docker exec -it dc1 samba-tool user create <username> --random-password
   ```

3. **Access phpLDAPadmin:**
   - Navigate to `https://<host-ip>:6443`
   - Login DN: `cn=Administrator,cn=Users,DC=cyberrange,DC=local`
   - Password: (from ADMIN_PASSWORD in .env)

#### Web Server Access

- URL: `http://<host-ip>:5000`
- Default credentials: `admin` / `admin123`
- **Warning:** Contains intentional vulnerabilities for training only

---

## 🎮 Training Scenarios

### Exercise Narrative

Blue Land and Red Land stand on the brink of a new frontier in conflict. Their long-standing territorial disputes have shifted from the borderlands into cyberspace, where battles are now unfolding in real time. Red Land is actively deploying modern cyber warfare strategies to destabilize Blue Land, while Blue Land's Computer Emergency Response Team (CERT-Blue Land) coordinates the national response to ongoing attacks.

### Red Team Mission Plan

**Exercise Constraints:** All activities occur strictly inside the training scope: on pre-provisioned lab replicas, synthetic datasets, or publicly available non-sensitive information only. No real systems, no credential harvesting, no destructive actions.

#### Phase 1 — Reconnaissance
**Objective:** Build a comprehensive, non-intrusive picture of Blue Land's digital footprint.

- Collect publicly available information
- Map the attack surface conceptually
- Deliver ranked list of externally visible assets

**Blue Team Observables:** Unusual spikes in access to public pages, increased scraping activity, new open-source indicators.

#### Phase 2 — Pre-Exploitation
**Objective:** Validate attack hypotheses through safe, controlled simulation.

- Create believable engagement templates
- Test social engineering scenarios
- Validate surface-level misconfigurations

**Blue Team Observables:** User reporting behavior, email filtering logs, authentication anomalies.

#### Phase 3 — Post-Exploitation Emulation
**Objective:** Emulate consequences of a successful compromise in a controlled manner.

- Execute impact emulation on test assets
- Demonstrate lateral movement patterns
- Generate forensic artifacts for Blue Team analysis

**Blue Team Observables:** SIEM alerts, endpoint telemetry, network data flows.

### Blue Team Tactical Narrative

**Context & Rules:** All activity is defensive and confined to the exercise scope. Controllers maintain a live kill-switch.

#### Phase 1 — Reconnaissance Detection
**Objective:** Detect, profile and harden against public-footprint intelligence collection.

- Maintain authoritative asset registry
- Monitor public web and DNS telemetry
- Detect unusual crawling patterns

#### Phase 2 — Pre-Exploitation Defense
**Objective:** Detect, contain, and improve resilience to social engineering.

- Operate incident intake pipeline
- Maintain email filtering rules
- Validate authentication hardening

#### Phase 3 — Post-Exploitation Response
**Objective:** Detect, contain, and recover from a simulated breach.

- Maintain SIEM/analytics dashboards
- Practice containment procedures
- Perform forensic analysis

### Exercise Timeline

**Suggested one-day schedule:**
- **09:00–10:30**: Phase 1 monitoring and asset registry update
- **10:30–12:30**: Phase 2 simulated social engineering run and triage
- **13:30–16:00**: Phase 3 simulated breach detection, containment, and forensic reconstruction
- **16:00–17:00**: Scoring, debrief, and remediation planning

### Key Roles

- Blue Team Lead
- SOC Analysts
- Incident Responder / Forensic Analyst
- Communications Officer
- Exercise Controller

---

## 🔧 Management & Operations

### View Services Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f blue_land_secure_gateway
docker-compose logs -f vulnerable_webserver
```

### Stop All Services
```bash
docker-compose down
```

### Stop and Remove Volumes (⚠️ Data Loss)
```bash
docker-compose down -v
```

### Restart Specific Service
```bash
docker-compose restart dc1
```

### Update and Rebuild
```bash
docker-compose pull
docker-compose build --no-cache
docker-compose up -d
```

### Cleanup
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (⚠️ deletes all data)
docker-compose down -v

# Remove images (optional)
docker-compose down --rmi all
```

---

## 🔍 Troubleshooting

### Network Issues

- **macvlan network errors**: Ensure the host interface name in `.env` is correct
- **Container IP conflicts**: Adjust IP ranges in `.env` to avoid conflicts
- **DNS resolution issues**: Verify `MAIN_DNS_IP` and `DC_IP` settings

### Active Directory Issues

- **Domain join failures**: Ensure `dc1` is fully started before starting `fs1`
- **LDAP connection errors**: Check firewall rules and network connectivity
- **Permission errors**: Verify volume mounts have correct permissions

### VPN Issues

- **Cannot access admin UI**: Check if ports are properly exposed and firewall allows access
- **Client connection failures**: Verify VPN subnet configuration doesn't conflict with existing networks

---

## 🔒 Security Considerations

⚠️ **Important Security Notes:**

1. **Training Environment Only**: This setup is designed for isolated training environments. Do not deploy in production or on networks with sensitive data.

2. **Default Credentials**: Change all default passwords immediately after deployment.

3. **Network Isolation**: Ensure the training network is isolated from production networks.

4. **Vulnerable Components**: The web server intentionally contains vulnerabilities. Never expose to the internet.

5. **VPN Security**: Configure OpenVPN with strong authentication and encryption before use.

6. **Data Persistence**: Volumes contain sensitive training data. Secure volume storage appropriately.

---

## 📚 Support & Documentation

### Additional Resources

- **Active Directory Setup**: See `ENV/AD/DCserver/README.md` for detailed AD configuration
- **OpenVPN Documentation**: https://openvpn.net/community-resources/
- **Samba AD Documentation**: https://wiki.samba.org/index.php/User_and_Group_management

### Sample Artifacts

To pre-provision for exercises:
- Synthetic asset inventory CSV
- Persona profiles
- Test mailboxes and safe phishing simulation page
- Synthetic logs with injected anomalies
- Scoring sheet template

### Debrief Prompts

- Which reconnaissance signals were missed?
- How quickly did users report suspicious messages?
- Which telemetry sources were decisive in reconstructing the timeline?
- What immediate control changes will reduce likelihood/severity of simulated scenarios?

---

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

**All content is for authorized training use only.** Activities should be conducted against pre-provisioned lab replicas, synthetic data, or public sources only. No real systems or sensitive data should be used. Controllers maintain a live kill-switch for all exercises.
