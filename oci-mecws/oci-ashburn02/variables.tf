variable "tenancy_ocid" {
  type    = string
  default = "ocid1.tenancy.oc1..aaaaaaaabnq6zphstv3qlafbwf4nu3falzfezd5x76bueyanxhuagq37shna"
}

variable "region" {
  type    = string
  default = "us-ashburn-1"
}

variable "instance_name" {
  type    = string
  default = "oci-ashburn02"
}

# Always Free covers 200 GB of block storage in total across the tenancy.
variable "boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

# Attach the shared public-ssh NSG. Off: SSH only via Tailscale (oci-ashburn02 / 100.116.22.120).
variable "public_ssh" {
  type    = bool
  default = false
}
