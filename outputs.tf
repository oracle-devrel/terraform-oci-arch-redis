## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "generated_ssh_private_key" {
  value     = tls_private_key.public_private_key_pair.private_key_pem
  sensitive = true
}

output "generated_ssh_public_key" {
  value     = tls_private_key.public_private_key_pair.public_key_openssh
  sensitive = true
}

output "redis-masters_private_ips" {
  value = data.oci_core_vnic.redis_master_vnic.*.private_ip_address
}

output "redis-replicas_private_ips" {
  value = data.oci_core_vnic.redis_replica_vnic.*.private_ip_address
}

output "redis_password" {
  value = random_string.redis_password.result
}

output "bastion_ssh_redis_master_session_metadata" {
  value = oci_bastion_session.ssh_redis_master_session.*.ssh_metadata
}

output "bastion_ssh_redis_replica_session_metadata" {
  value = oci_bastion_session.ssh_redis_replica_session.*.ssh_metadata
}