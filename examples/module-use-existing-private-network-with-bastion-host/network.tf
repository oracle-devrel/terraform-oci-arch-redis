## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  tcp_protocol  = "6"
  all_protocols = "all"
  anywhere      = "0.0.0.0/0"
}

resource "oci_core_vcn" "my_vcn" {
  cidr_block     = "192.168.0.0/16"
  dns_label      = "myvcn"
  compartment_id = var.compartment_ocid
  display_name   = "my_vcn"
}

resource "oci_core_internet_gateway" "my_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.my_vcn.id
  display_name   = "my_igw"
}

resource "oci_core_route_table" "my_rt_via_igw" {
  compartment_id = var.compartment_ocid
  display_name   = "my_rt_via_igw"
  vcn_id         = oci_core_vcn.my_vcn.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.my_igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_nat_gateway" "my_nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.my_vcn.id
  display_name   = "my_nat"
}

resource "oci_core_route_table" "my_rt_via_nat" {
  compartment_id = var.compartment_ocid
  display_name   = "my_rt_via_nat"
  vcn_id         = oci_core_vcn.my_vcn.id

  route_rules {
    network_entity_id = oci_core_nat_gateway.my_nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "my_redis_sec_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.my_vcn.id
  display_name   = "my_redis_sec_list"

  egress_security_rules {
    protocol    = local.tcp_protocol
    destination = local.anywhere
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = local.anywhere

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = local.anywhere

    tcp_options {
      max = "6379"
      min = "6379"
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = local.anywhere

    tcp_options {
      max = "16379"
      min = "16379"
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = "192.168.0.0/16"

    tcp_options {
      max = "26379"
      min = "26379"
    }
  }
}

resource "oci_core_subnet" "my_compute_public_subnet" {
  cidr_block        = "192.168.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.my_vcn.id
  dns_label         = "pubsub"
  security_list_ids = [oci_core_security_list.my_redis_sec_list.id]
  route_table_id    = oci_core_route_table.my_rt_via_igw.id
  display_name      = "my_compute_public_subnet"
}

resource "oci_core_subnet" "my_compute_private_subnet" {
  cidr_block        = "192.168.2.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.my_vcn.id
  dns_label         = "privsub"
  security_list_ids = [oci_core_security_list.my_redis_sec_list.id]
  route_table_id    = oci_core_route_table.my_rt_via_nat.id
  display_name      = "my_compute_private_subnet"
  prohibit_public_ip_on_vnic = "true"
}



