variable "tenancy_ocid" {
  type    = string
  default = "ocid1.tenancy.oc1..aaaaaaaabnq6zphstv3qlafbwf4nu3falzfezd5x76bueyanxhuagq37shna"
}

variable "region" {
  type    = string
  default = "us-ashburn-1"
}

# A1 capacity in Ashburn is often exhausted; try 1, 2 or 3 if apply fails with "Out of host capacity".
variable "availability_domain_number" {
  type    = number
  default = 1
}

# Always Free covers 4 OCPU / 24 GB of A1 in total. Anything above that is billed.
variable "ocpus" {
  type    = number
  default = 1
}

variable "memory_in_gbs" {
  type    = number
  default = 6
}

# Always Free covers 200 GB of block storage in total.
variable "boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "instance_name" {
  type    = string
  default = "sbcloud-a1"
}

variable "micro_instance_name" {
  type    = string
  default = "oci-ashburn01"
}

# Attach the public-ssh NSG (port 22 from ssh_allowed_cidr). Off = SSH only via Tailscale.
# The A1 has no Tailscale until it's set up, so it starts with public SSH on.
variable "public_ssh_a1" {
  type    = bool
  default = true
}

variable "public_ssh_micro" {
  type    = bool
  default = false
}
