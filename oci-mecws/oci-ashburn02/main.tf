# Second Always Free E2.1.Micro (AMD, AD-1 only: 1/8 OCPU, 1 GB).
# Uses the compartment, subnet and public-ssh NSG managed by ../terraform; this folder only owns the instance.

data "oci_identity_compartments" "this" {
  compartment_id = var.tenancy_ocid
  name           = "sbprivatecloud"
}

locals {
  compartment_id = data.oci_identity_compartments.this.compartments[0].id
}

data "oci_core_vcns" "this" {
  compartment_id = local.compartment_id
  display_name   = "sbcloud-vcn"
}

data "oci_core_subnets" "public" {
  compartment_id = local.compartment_id
  vcn_id         = data.oci_core_vcns.this.virtual_networks[0].id
  display_name   = "sbcloud-public"
}

data "oci_core_network_security_groups" "public_ssh" {
  compartment_id = local.compartment_id
  vcn_id         = data.oci_core_vcns.this.virtual_networks[0].id
  display_name   = "public-ssh"
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_core_images" "ubuntu_minimal_amd" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04 Minimal"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "this" {
  compartment_id      = local.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad1.name
  display_name        = var.instance_name
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_minimal_amd.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = data.oci_core_subnets.public.subnets[0].id
    assign_public_ip = true
    hostname_label   = var.instance_name
    nsg_ids          = var.public_ssh ? [data.oci_core_network_security_groups.public_ssh.network_security_groups[0].id] : []
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}
