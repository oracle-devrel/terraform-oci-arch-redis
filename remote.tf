## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "redis_bootstrap_master_template" {
  count    = var.numberOfMasterNodes
  template = file("${path.module}/scripts/redis_bootstrap_master.sh")

  vars = {
    redis_version      = var.redis_version
    redis_port1        = var.redis_port1
    redis_port2        = var.redis_port2
    sentinel_port      = var.sentinel_port
    redis_password     = random_string.redis_password.result
    master_private_ip  = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
    master_fqdn        = join("", [data.oci_core_vnic.redis_master_vnic[count.index].hostname_label, ".", var.redis-prefix, ".", var.redis-prefix, ".oraclevcn.com"])
    cluster_enabled    = var.cluster_enabled
    add_iscsi_volume   = var.add_iscsi_volume
  }
}

data "template_file" "redis_bootstrap_replica_template" {
  count    = var.numberOfReplicaNodes
  template = file("${path.module}/scripts/redis_bootstrap_replica.sh")

  vars = {
    redis_version      = var.redis_version
    redis_port1        = var.redis_port1
    redis_port2        = var.redis_port2
    sentinel_port      = var.sentinel_port
    redis_password     = random_string.redis_password.result
    master_private_ip  = data.oci_core_vnic.redis_master_vnic[0].private_ip_address
    master_fqdn        = join("", [data.oci_core_vnic.redis_master_vnic[0].hostname_label, ".", var.redis-prefix, ".", var.redis-prefix, ".oraclevcn.com"])
    cluster_enabled    = var.cluster_enabled
    add_iscsi_volume   = var.add_iscsi_volume
  }
}

data "template_file" "redis_bootstrap_cluster_template" {
  count      = var.cluster_enabled ? 1 : 0
  template   = file("${path.module}/scripts/redis_bootstrap_cluster.sh")

  vars = {
    redis_master_private_ips_with_port  = local.redis_master_private_ips_with_port
    redis_replica_private_ips_with_port = local.redis_replica_private_ips_with_port
    redis_password                      = random_string.redis_password.result
  }
}

resource "null_resource" "redis_master_attach_volume_without_bastion" {
  count      = local.redis_master_attach_volume_without_bastion
  depends_on = [oci_core_instance.redis_master, oci_core_volume.redis_master_volume, oci_core_volume_attachment.redis_master_volume_attachment]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /redisvol",
      "sudo -u root mount /dev/sdb1 /redisvol",
      "sudo /bin/su -c \"echo '/dev/sdb1              /redisvol  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }
}

resource "null_resource" "redis_master_bootstrap_without_bastion" {
  count      = local.redis_master_bootstrap_without_bastion
  depends_on = [oci_core_instance.redis_master, oci_core_instance.redis_replica, null_resource.redis_master_attach_volume_without_bastion]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }

    content     = data.template_file.redis_bootstrap_master_template[count.index].rendered
    destination = "~/redis_bootstrap_master.sh"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = [
      "chmod +x ~/redis_bootstrap_master.sh",
      "sudo ~/redis_bootstrap_master.sh",
    ]
  }
}

resource "null_resource" "redis_master_attach_volume_with_bastion" {
  count      = local.redis_master_attach_volume_with_bastion
  depends_on = [oci_core_instance.redis_master, oci_core_volume.redis_master_volume, oci_core_volume_attachment.redis_master_volume_attachment]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_master_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_master_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_master_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_master_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /redisvol",
      "sudo -u root mount /dev/sdb1 /redisvol",
      "sudo /bin/su -c \"echo '/dev/sdb1              /redisvol  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }
}

resource "null_resource" "redis_master_bootstrap_with_bastion" {
  count      = local.redis_master_bootstrap_with_bastion
  depends_on = [oci_core_instance.redis_master, oci_core_instance.redis_replica, null_resource.redis_master_attach_volume_with_bastion]

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_master_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }

    content     = data.template_file.redis_bootstrap_master_template[count.index].rendered
    destination = "~/redis_bootstrap_master.sh"
  }
  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_master_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = [
      "chmod +x ~/redis_bootstrap_master.sh",
      "sudo ~/redis_bootstrap_master.sh",
    ]
  }
}

resource "null_resource" "redis_replica_attach_volume_without_bastion" {
  count      = local.redis_replica_attach_volume_without_bastion
  depends_on = [oci_core_instance.redis_replica, oci_core_volume.redis_replica_volume, oci_core_volume_attachment.redis_replica_volume_attachment]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_replica_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_replica_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_replica_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_replica_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /redisvol",
      "sudo -u root mount /dev/sdb1 /redisvol",
      "sudo /bin/su -c \"echo '/dev/sdb1              /redisvol  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }
}

resource "null_resource" "redis_replica_bootstrap_without_bastion" {
  count      = local.redis_replica_bootstrap_without_bastion
  depends_on = [oci_core_instance.redis_master, oci_core_instance.redis_replica, null_resource.redis_replica_attach_volume_without_bastion]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_replica_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }

    content     = data.template_file.redis_bootstrap_replica_template[count.index].rendered
    destination = "~/redis_bootstrap_replica.sh"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_replica_vnic[count.index].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = [
      "chmod +x ~/redis_bootstrap_replica.sh",
      "sudo ~/redis_bootstrap_replica.sh",
    ]
  }
}

resource "null_resource" "redis_replica_attach_volume_with_bastion" {
  count      = local.redis_replica_attach_volume_with_bastion
  depends_on = [oci_core_instance.redis_replica, oci_core_volume.redis_replica_volume, oci_core_volume_attachment.redis_replica_volume_attachment]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_replica_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_replica_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_replica_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_replica_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /redisvol",
      "sudo -u root mount /dev/sdb1 /redisvol",
      "sudo /bin/su -c \"echo '/dev/sdb1              /redisvol  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }
}

resource "null_resource" "redis_replica_bootstrap_with_bastion" {
  count      = local.redis_replica_bootstrap_with_bastion
  depends_on = [oci_core_instance.redis_master, oci_core_instance.redis_replica, null_resource.redis_replica_attach_volume_with_bastion]

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_replica_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }

    content     = data.template_file.redis_bootstrap_replica_template[count.index].rendered
    destination = "~/redis_bootstrap_replica.sh"
  }
  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_replica_vnic[count.index].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = [
      "chmod +x ~/redis_bootstrap_replica.sh",
      "sudo ~/redis_bootstrap_replica.sh",
    ]
  }
}

resource "null_resource" "redis_cluster_setup_without_bastion" {
  count      = local.redis_cluster_without_bastion
  depends_on = [null_resource.redis_master_bootstrap_without_bastion, null_resource.redis_replica_bootstrap_without_bastion]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[0].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }

    content     = data.template_file.redis_bootstrap_cluster_template[0].rendered
    destination = "~/redis_bootstrap_cluster.sh"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.redis_master_vnic[0].public_ip_address
      private_key = tls_private_key.public_private_key_pair.private_key_pem
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = [
      "chmod +x ~/redis_bootstrap_cluster.sh",
      "sudo ~/redis_bootstrap_cluster.sh",
    ]
  }
}

resource "null_resource" "redis_cluster_setup_with_bastion" {
  count      = local.redis_cluster_with_bastion
  depends_on = [null_resource.redis_master_bootstrap_with_bastion, null_resource.redis_replica_bootstrap_with_bastion]

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[0].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }

    content     = data.template_file.redis_bootstrap_cluster_template[0].rendered
    destination = "~/redis_bootstrap_cluster.sh"
  }
  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = data.oci_core_vnic.redis_master_vnic[0].private_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.use_private_subnet && var.use_bastion_service ? "host.bastion.${var.region}.oci.oraclecloud.com" : var.bastion_server_public_ip
      bastion_port        = "22" 
      bastion_user        = var.use_private_subnet && var.use_bastion_service ? oci_bastion_session.ssh_redis_replica_session[count.index].id : "opc"
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem 
    }
    inline = [
      "chmod +x ~/redis_bootstrap_cluster.sh",
      "sudo ~/redis_bootstrap_cluster.sh",
    ]
  }
}