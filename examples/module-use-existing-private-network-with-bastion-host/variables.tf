## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

variable "bastion_shape" {
  description = "Instance Shape"
  default     = "VM.Standard.E4.Flex"
}

variable "bastion_flex_shape_ocpus" {
  default = 1
}

variable "bastion_flex_shape_memory" {
  default = 1
}

variable "availability_domain_name" {
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

locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex"
  ]
  is_flexible_node_shape                  = contains(local.compute_flexible_shapes, var.bastion_shape)
  availability_domain_name                = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name") : var.availability_domain_name
}
