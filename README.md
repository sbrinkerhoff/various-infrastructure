# various-infrastructure

Monorepo for cloud infrastructure, automation scripts, and deployment configurations across private clouds and external providers.

## Repository Layout

```text
various-infrastructure/
├── .gitignore
├── README.md
├── mplr-edge01/                 # Dell Edge 640 physical edge router & KVM hypervisor
│   ├── README.md                # System specs, network architecture, and runbook
│   └── config/
│       ├── 01-netcfg.yaml       # Netplan host bridging (br-wan, br-lan)
│       └── opnsense.xml         # Libvirt domain XML definition for OPNsense 24.7
└── oci-mecws/                   # Oracle Cloud Infrastructure (OCI) environment
    ├── README.md                # In-depth architectural & operational guide
    ├── creds/                   # OCI API signing keys (git-ignored)
    └── terraform/               # Terraform IaC definitions & capacity loop
        ├── main.tf              # OCI VCN, Subnet, NSGs, and Compute instances
        ├── variables.tf         # Resource parameters and security toggles
        ├── outputs.tf           # Computed IPs, shapes, and SSH commands
        ├── versions.tf          # Terraform and OCI provider constraints
        ├── retry-apply.sh       # Automated retry loop for Ashburn A1 Flex capacity
        └── instance.auto.tfvars # Pinned AD & shape parameters upon successful allocation
```

## Projects & Environments

### [mplr-edge01](file:///Users/stanbrinkerhoff/git/various-infrastructure/mplr-edge01/README.md)
Dell EMC Virtual Edge Platform (VEP) 640 physical edge appliance hosting a virtualized OPNsense 24.7 firewall on Ubuntu 26.04 LTS via KVM / QEMU.

- **Hardware**: Intel Atom C3758 (8 cores @ 2.20 GHz), 30 GB ECC RAM, 240 GB SSD.
- **Network Interfaces**: 8 physical ports (4x 1GbE I350, 2x 1GbE X553, 2x 10GbE X553 SFP+).
- **Hypervisor Bridging**: Netplan bridges `eno6` (uplink) + `ens2f1` into `br-lan` (Host: `192.168.40.104/24`), and `ens2f0` into `br-wan`.
- **OPNsense Firewall VM**:
  - `vtnet0` (WAN): Attached to `br-wan` (physical `ens2f0`).
  - `vtnet1` (LAN): Attached to `br-lan` (`192.168.40.2/24`, Web UI HTTPS, DHCP disabled).
  - UEFI OVMF firmware, 4 vCPUs, 8 GB RAM, VirtIO disk and networking.
- **Configuration & XML**:
  - [`mplr-edge01/config/01-netcfg.yaml`](file:///Users/stanbrinkerhoff/git/various-infrastructure/mplr-edge01/config/01-netcfg.yaml)
  - [`mplr-edge01/config/opnsense.xml`](file:///Users/stanbrinkerhoff/git/various-infrastructure/mplr-edge01/config/opnsense.xml)

Refer to [`mplr-edge01/README.md`](file:///Users/stanbrinkerhoff/git/various-infrastructure/mplr-edge01/README.md) for full architecture diagrams, tuning guides (VirtIO offload), and operational runbooks.

### [oci-mecws](file:///Users/stanbrinkerhoff/git/various-infrastructure/oci-mecws/README.md)
Contains the Infrastructure as Code (Terraform) and operational runbooks for the **sbpersonalcloud** Oracle Cloud tenancy in `us-ashburn-1` (IAD).

- **Terraform Directory**: [`oci-mecws/terraform`](file:///Users/stanbrinkerhoff/git/various-infrastructure/oci-mecws/terraform)
  - Provisions Always-Free tier compute resources (`oci-ashburn01` E2.1.Micro and `sbcloud-a1` A1.Flex).
  - Manages Virtual Cloud Network (VCN), security lists, route tables, and Network Security Groups (NSGs).
  - Provides an automated capacity acquisition script [`retry-apply.sh`](file:///Users/stanbrinkerhoff/git/various-infrastructure/oci-mecws/terraform/retry-apply.sh) to claim scarce Ampere A1 instances in Ashburn.

- **System Integrations on `oci-ashburn01`**:
  - **Tailscale Mesh**: Zero-trust administrative network. The host has all public inbound ports (including SSH port 22) closed from the internet. All management, deployment, and SSH sessions run over the private Tailscale mesh (`100.77.132.0` / `oci-ashburn01`). The VM also serves as an authorized Tailscale Exit Node.
  - **Cloudflare Tunnel**: Edge ingress for public web services (`ops.mecws.org`). The `cloudflared` container establishes an outbound tunnel connection to Cloudflare's global edge network, eliminating the need for open inbound ports, port forwarding, or exposed public IPs.
  - **MECWS Volunteer Operations**: Production container running the volunteer management platform on `localhost:5000`, connected to Cloudflare and backed by a persistent SQLite database with Write-Ahead Logging (WAL) mode.

Refer to [`oci-mecws/README.md`](file:///Users/stanbrinkerhoff/git/various-infrastructure/oci-mecws/README.md) for full architecture diagrams, setup instructions, and operational commands.
