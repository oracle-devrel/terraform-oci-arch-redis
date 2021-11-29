## Copyright (c) 2021 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "random_id" "dynamic_group" {
  byte_length = 2
}

resource "oci_identity_dynamic_group" "redis_dynamic_group" {

  provider = oci.homeregion

  compartment_id = var.tenancy_ocid

  name        = "redis-cluster-dynamic-group-${random_id.dynamic_group.hex}"
  description = "Dynamic group of Redis cluster Compute instances"

  matching_rule = "tag.${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}.value = '${var.release}'"
}
