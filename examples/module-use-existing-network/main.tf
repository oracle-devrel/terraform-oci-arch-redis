## Copyright (c) 2021 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

module "oci-arch-redis" {
  source           = "github.com/oracle-devrel/terraform-oci-arch-redis"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  region           = var.region
  private_key_path = var.private_key_path
  compartment_ocid = var.compartment_ocid
  use_existing_vcn = true
  vcn_id           = oci_core_vcn.my_vcn.id
  redis_subnet_id  = oci_core_subnet.my_compute_subnet.id
}

output "generated_ssh_private_key" {
  value     = module.oci-arch-redis.generated_ssh_private_key
  sensitive = true
}
