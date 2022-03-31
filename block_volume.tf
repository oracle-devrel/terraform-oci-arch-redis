## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_volume" "redis_master_volume" {
  count               = var.numberOfMasterNodes > 0  && var.add_iscsi_volume ? var.numberOfMasterNodes : 0
  availability_domain = local.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "redis_master_volume${count.index+1}"
  size_in_gbs         = var.iscsi_volume_size_in_gbs
  defined_tags        = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_volume_attachment" "redis_master_volume_attachment" {
  count           = var.numberOfMasterNodes > 0  && var.add_iscsi_volume ? var.numberOfMasterNodes : 0
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.redis_master[count.index].id
  volume_id       = oci_core_volume.redis_master_volume[count.index].id
}

resource "oci_core_volume" "redis_replica_volume" {
  count               = var.numberOfReplicaNodes > 0  && var.add_iscsi_volume ? var.numberOfReplicaNodes : 0
  availability_domain = local.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "redis_replica_volume${count.index+1}"
  size_in_gbs         = var.iscsi_volume_size_in_gbs
  defined_tags        = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_volume_attachment" "redis_replica_volume_attachment" {
  count           = var.numberOfReplicaNodes > 0  && var.add_iscsi_volume ? var.numberOfReplicaNodes : 0
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.redis_replica[count.index].id
  volume_id       = oci_core_volume.redis_replica_volume[count.index].id
}
