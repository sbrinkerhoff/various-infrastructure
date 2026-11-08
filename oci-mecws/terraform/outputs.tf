output "public_ip" {
  value = oci_core_instance.this.public_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${oci_core_instance.this.public_ip}"
}

output "image" {
  value = data.oci_core_images.ubuntu.images[0].display_name
}

output "micro_public_ip" {
  value = oci_core_instance.micro.public_ip
}

output "micro_ssh_command" {
  value = "ssh ubuntu@${oci_core_instance.micro.public_ip}"
}
