#!/bin/bash
set -x
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/tflog.out 2>&1

REDIS_VERSION="5.0.7"
REDIS_CONFIG_FILE=/etc/redis.conf
SENTINEL_CONFIG_FILE=/etc/sentinel.conf

# Setup firewall rules
firewall-offline-cmd  --zone=public --add-port=${redis_port1}/tcp
firewall-offline-cmd  --zone=public --add-port=${redis_port2}/tcp
firewall-offline-cmd  --zone=public --add-port=${sentinel_port}/tcp
systemctl restart firewalld

# To avoid warining: WARNING overcommit_memory is set to 0! Background save may fail under low memory condition.
sysctl vm.overcommit_memory=1

# Install wget and gcc
yum install -y wget gcc

# Download and compile Redis
wget http://download.redis.io/releases/redis-${redis_version}.tar.gz
tar xvzf redis-${redis_version}.tar.gz
cd redis-${redis_version}
make install

export cluster_enabled='${cluster_enabled}'

if [[ $cluster_enabled == "true" ]]; then
# Configure Redis Config File
cat << EOF > $REDIS_CONFIG_FILE
port ${redis_port1}
dir /home/redis/redis
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-slave-validity-factor 0
appendonly yes
requirepass ${redis_password}
masterauth ${redis_password}

EOF
else
# Configure Redis Config File
cat << EOF > $REDIS_CONFIG_FILE
port ${redis_port1}
dir /home/redis/redis
replicaof ${master_private_ip} ${redis_port1}
cluster-enabled no
appendonly yes
requirepass ${redis_password}
masterauth ${redis_password}
EOF
fi

# Configure Sentinel Config File
cat << EOF > $SENTINEL_CONFIG_FILE
port ${sentinel_port}
dir /home/redis/sentinel
sentinel monitor ${master_fqdn} ${master_private_ip} ${redis_port1} 2
sentinel auth-pass ${master_fqdn} ${redis_password}

EOF

sleep 30

# Checks if the redis user already exists before attempting to create one
id -u redis &>/dev/null || sudo useradd redis
mkdir /home/redis/redis
chown -R redis:redis /home/redis/redis
mkdir /home/redis/sentinel
chown -R redis:redis /home/redis/sentinel

# Configuring Redis Linux Service
sudo tee /usr/lib/systemd/system/redis.service > /dev/null << EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
User=redis
Group=redis
LimitNOFILE=65536
Type=notify
ExecStart=/usr/local/bin/redis-server $REDIS_CONFIG_FILE --supervised systemd
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

chown -R redis:redis $REDIS_CONFIG_FILE
chmod -R 755 $REDIS_CONFIG_FILE

sudo systemctl daemon-reload
sudo systemctl enable redis
sudo systemctl restart redis
sudo systemctl status redis

# Configuring Sentinel Linux Service
sudo tee /usr/lib/systemd/system/redis-sentinel.service > /dev/null << EOF
[Unit]
Description=Redis Sentinel
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-sentinel $SENTINEL_CONFIG_FILE
ExecStop=/usr/local/bin/redis-cli -h 127.0.0.1 -p ${sentinel_port} shutdown
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

chown -R redis:redis $SENTINEL_CONFIG_FILE
chmod -R 755 $SENTINEL_CONFIG_FILE

systemctl daemon-reload
systemctl enable redis-sentinel
systemctl restart redis-sentinel
systemctl status redis-sentinel

