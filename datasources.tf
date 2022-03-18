## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Get list of availability domains

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.instance_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

data "oci_core_vnic_attachments" "redis_master_vnics" {
  count               = var.numberOfMasterNodes
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain_name
  instance_id         = oci_core_instance.redis_master[count.index].id
}

data "oci_core_vnic" "redis_master_vnic" {
  count               = var.numberOfMasterNodes
  vnic_id = data.oci_core_vnic_attachments.redis_master_vnics[count.index].vnic_attachments.0.vnic_id
}

data "oci_core_vnic_attachments" "redis_replica_vnics" {
  count               = var.numberOfReplicaNodes
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain_name
  instance_id         = oci_core_instance.redis_replica[count.index].id
}

data "oci_core_vnic" "redis_replica_vnic" {
  count               = var.numberOfReplicaNodes
  vnic_id             = data.oci_core_vnic_attachments.redis_replica_vnics[count.index].vnic_attachments.0.vnic_id
}


data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}

