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

resource "null_resource" "redis_master_bootstrap" {
  count      = var.numberOfMasterNodes
  depends_on = [oci_core_instance.redis_master, oci_core_instance.redis_replica]

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

resource "null_resource" "redis_replica_bootstrap" {
  count      = var.numberOfReplicaNodes
  depends_on = [oci_core_instance.redis_master, oci_core_instance.redis_replica]

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

resource "null_resource" "redis_cluster_startup" {
  count      = var.cluster_enabled ? 1 : 0
  depends_on = [null_resource.redis_master_bootstrap, null_resource.redis_replica_bootstrap]

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
