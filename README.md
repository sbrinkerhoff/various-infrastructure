# various-infrastructure

Monorepo for cloud infrastructure, automation scripts, and deployment configurations across private clouds and external providers.

## Repository Layout

```text
various-infrastructure/
├── .gitignore
├── README.md
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
