#!/bin/bash
set -x
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/tflog_cluster.out 2>&1

sleep 60

/usr/local/bin/redis-cli --cluster create ${redis_master_private_ips_with_port}:6379 ${redis_replica_private_ips_with_port}:6379 -a ${redis_password} --cluster-replicas 1 --cluster-yes
echo 'cluster info' | /usr/local/bin/redis-cli -c -a ${redis_password}
echo 'cluster nodes' | /usr/local/bin/redis-cli -c -a ${redis_password}
