output "public_ip" {
  value = oci_core_instance.this.public_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${oci_core_instance.this.public_ip}"
}

output "image" {
  value = data.oci_core_images.ubuntu_minimal_amd.images[0].display_name
}
