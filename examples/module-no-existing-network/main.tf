## Copyright (c) 2022 Oracle and/or its affiliates.
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
  # Cluster scenario (bare minimum = 3 masterVMs, 3 replicaVMs)
  numberOfMasterNodes  = 3
  numberOfReplicaNodes = 3
  cluster_enabled      = true
}

output "generated_ssh_private_key" {
  value     = module.oci-arch-redis.generated_ssh_private_key
  sensitive = true
}

