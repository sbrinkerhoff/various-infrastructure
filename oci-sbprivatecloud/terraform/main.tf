resource "oci_identity_compartment" "this" {
  compartment_id = var.tenancy_ocid
  name           = "sbprivatecloud"
  description    = "Managed by Terraform (oci-sbprivatecloud)"
  enable_delete  = true
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.availability_domain_number
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --- Network ---

resource "oci_core_vcn" "this" {
  compartment_id = oci_identity_compartment.this.id
  display_name   = "sbcloud-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "sbcloud"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sbcloud-igw"
}

resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sbcloud-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "sbcloud-public-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH is not opened here (subnet-wide); attach the public-ssh NSG per instance instead.

  # ICMP fragmentation-needed, so path MTU discovery works.
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "public" {
  compartment_id    = oci_identity_compartment.this.id
  vcn_id            = oci_core_vcn.this.id
  display_name      = "sbcloud-public"
  cidr_block        = "10.0.1.0/24"
  dns_label         = "public"
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]
}

# Public SSH, attached per instance via public_ssh_* toggles.
resource "oci_core_network_security_group" "public_ssh" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "public-ssh"
}

resource "oci_core_network_security_group_security_rule" "public_ssh" {
  network_security_group_id = oci_core_network_security_group.public_ssh.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.ssh_allowed_cidr
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# --- Instance ---

resource "oci_core_instance" "this" {
  compartment_id      = oci_identity_compartment.this.id
  availability_domain = data.oci_identity_availability_domain.ad.name
  display_name        = var.instance_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = var.instance_name
    nsg_ids          = var.public_ssh_a1 ? [oci_core_network_security_group.public_ssh.id] : []
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

# --- E2.1.Micro instance (Always Free AMD, AD-1 only: 1/8 OCPU, 1 GB) ---

data "oci_core_images" "ubuntu_minimal_amd" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04 Minimal"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

resource "oci_core_instance" "micro" {
  compartment_id      = oci_identity_compartment.this.id
  availability_domain = data.oci_identity_availability_domain.ad1.name
  display_name        = var.micro_instance_name
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_minimal_amd.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = var.micro_instance_name
    nsg_ids          = var.public_ssh_micro ? [oci_core_network_security_group.public_ssh.id] : []
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}
