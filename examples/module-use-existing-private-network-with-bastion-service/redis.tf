## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

module "arch-redis" {
  #source                    = "github.com/oracle-devrel/terraform-oci-arch-redis"
  source                    = "../../"
  tenancy_ocid              = var.tenancy_ocid
  user_ocid                 = var.user_ocid
  fingerprint               = var.fingerprint
  region                    = var.region
  private_key_path          = var.private_key_path
  compartment_ocid          = var.compartment_ocid
  use_existing_vcn          = true
  vcn_id                    = oci_core_vcn.my_vcn.id # Passing VCN OCID
  use_private_subnet        = true # Enabling usage of Private Subnet for Redis
  redis_subnet_id           = oci_core_subnet.my_compute_private_subnet.id # Passing Private Subnet OCID.
  use_bastion_service       = true # Enabling usage of OCI Bastion Service
  inject_bastion_service_id = true # Don't create Bastion Service insdie module.
  bastion_service_id        = oci_bastion_bastion.bastion_service.id # Injecting Bastion Service OCID
  numberOfMasterNodes       = 1 # 1x Redis Master node
  numberOfReplicaNodes      = 2 # 2x Redis Replica nodes (required by Sentinel)
  cluster_enabled           = false # No cluster as number of Master and Replica nodes is limited.
}

