## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "generated_ssh_private_key" {
  value     = module.oci-arch-redis.generated_ssh_private_key
  sensitive = true
}

output "redis-masters_private_ips" {
  value = module.oci-arch-redis.redis-masters_private_ips
}

output "redis-replicas_private_ips" {
  value = module.oci-arch-redis.redis-replicas_private_ips
}

output "bastion_ssh_redis_master_session_metadata" {
  value = module.oci-arch-redis.bastion_ssh_redis_master_session_metadata
}

output "bastion_ssh_redis_replica_session_metadata" {
  value = module.oci-arch-redis.bastion_ssh_redis_replica_session_metadata
}