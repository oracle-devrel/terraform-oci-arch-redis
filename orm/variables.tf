## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
#variable "user_ocid" {}
#variable "fingerprint" {}
#variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

variable "availability_domain_name" {
  default = ""
}

variable "availability_domain_number" {
  default = 0
}

variable "release" {
  description = "Reference Architecture Release (OCI Architecture Center)"
  default     = "1.4"
}

variable "use_existing_vcn" {
  default = false
}

variable "use_redis_oci_logging" {
  default = false
}

variable "vcn_id" {
  default = ""
}

variable "redis_subnet_id" {
  default = ""
}

variable "use_private_subnet" {
  default = false
}

variable "use_bastion_service" {
  default = true
}

variable "bastion_server_public_ip" {
  default = ""
}

variable "inject_bastion_service_id" {
  default = false
}

variable "bastion_service_id" {
  default = ""
}

variable "numberOfMasterNodes" {
  default = 3
}

variable "numberOfReplicaNodes" {
  default = 3
}

variable "cluster_enabled" {
  default = true
}

variable "VCN-CIDR" {
  default = "10.0.0.0/16"
}

variable "Subnet-CIDR" {
  default = "10.0.1.0/24"
}

variable "redis-prefix" {
  default = "redis"
}

variable "redis_version" {
  default = "6.2.6"
}

variable "redis_port1" {
  default = "6379"
}

variable "redis_port2" {
  default = "16379"
}

variable "sentinel_port" {
  default = "26379"
}

variable "ssh_public_key" {
  default = ""
}

variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "7.9"
}

variable "instance_shape" {
  description = "Instance Shape"
  default     = "VM.Standard.E4.Flex"
}


variable "instance_flex_shape_ocpus" {
  default = 1
}

variable "instance_flex_shape_memory" {
  default = 10
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex"
  ]
}

# Checks if is using Flexible Compute Shapes
locals {
  is_flexible_node_shape                  = contains(local.compute_flexible_shapes, var.instance_shape)
  availability_domain_name                = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain_number], "name") : var.availability_domain_name
  redis_subnet_id                         = !var.use_existing_vcn ? oci_core_subnet.redis-subnet[0].id : var.redis_subnet_id
  vcn_id                                  = !var.use_existing_vcn ? oci_core_virtual_network.redis-vcn[0].id : var.vcn_id
  redis_master_private_ips_with_port      = join(":6379 ", data.oci_core_vnic.redis_master_vnic[*]["private_ip_address"])
  redis_replica_private_ips_with_port     = join(":6379 ", data.oci_core_vnic.redis_replica_vnic[*]["private_ip_address"])
  redis_master_bastion_count              = var.use_private_subnet ? var.numberOfMasterNodes : 0
  redis_replica_bastion_count             = var.use_private_subnet ? var.numberOfReplicaNodes : 0
  redis_master_bootstrap_without_bastion  = var.use_private_subnet ? 0 : var.numberOfMasterNodes
  redis_replica_bootstrap_without_bastion = var.use_private_subnet ? 0 : var.numberOfReplicaNodes 
  redis_master_bootstrap_with_bastion     = var.use_private_subnet ? var.numberOfMasterNodes : 0
  redis_replica_bootstrap_with_bastion    = var.use_private_subnet ? var.numberOfReplicaNodes : 0 
  redis_cluster_without_bastion           = !var.use_private_subnet && var.cluster_enabled ? 1 : 0
  redis_cluster_with_bastion              = var.use_private_subnet && var.cluster_enabled ? 1 : 0
}


