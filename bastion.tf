## Copyright (c) 2021 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_bastion_bastion" "bastion-service" {
  count                        = var.use_private_subnet ? 1 : 0
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = !var.use_existing_vcn ? oci_core_subnet.redis-subnet[0].id : var.redis_subnet_id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  defined_tags                 = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  name                         = "BastionService${random_id.tag.hex}"
  max_session_ttl_in_seconds   = 10800
}

resource "oci_bastion_session" "ssh_redis_master_session" {
  depends_on = [oci_core_instance.redis_master]
  
  count      = local.redis_master_bastion_count
  bastion_id = oci_bastion_bastion.bastion-service[0].id

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }
  target_resource_details {
    session_type       = "MANAGED_SSH"
    target_resource_id = oci_core_instance.redis_master[count.index].id

    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.redis_master[count.index].private_ip
  }

  display_name           = "ssh_redis_master_session"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}

resource "oci_bastion_session" "ssh_redis_replica_session" {
  depends_on = [oci_core_instance.redis_replica]

  count      = local.redis_replica_bastion_count
  bastion_id = oci_bastion_bastion.bastion-service[0].id

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }
  target_resource_details {
    session_type       = "MANAGED_SSH"
    target_resource_id = oci_core_instance.redis_replica[count.index].id

    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.redis_replica[count.index].private_ip
  }

  display_name           = "ssh_redis_replica_session"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}
