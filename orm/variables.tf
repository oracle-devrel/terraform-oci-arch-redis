## Copyright (c) 2021 Oracle and/or its affiliates.
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
  default     = "1.2.1"
}

variable "use_existing_vcn" {
  default = false
}

variable "vcn_id" {
  default = ""
}

variable "redis_subnet_id" {
  default = ""
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
  default = "5.0.7"
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
  default     = "VM.Standard.E3.Flex"
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
  is_flexible_node_shape   = contains(local.compute_flexible_shapes, var.instance_shape)
  availability_domain_name = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain_number], "name") : var.availability_domain_name
  redis_subnet_id          = !var.use_existing_vcn ? oci_core_subnet.redis-subnet[0].id : var.redis_subnet_id
  vcn_id                   = !var.use_existing_vcn ? oci_core_virtual_network.redis-vcn[0].id : var.vcn_id
}


