terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
  }
}

# Auth comes from the DEFAULT profile in ~/.oci/config.
provider "oci" {
  region              = var.region
  config_file_profile = "DEFAULT"
}
