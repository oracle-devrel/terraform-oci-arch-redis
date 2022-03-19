## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "redis-vcn" {
  count          = !var.use_existing_vcn ? 1 : 0
  cidr_block     = var.VCN-CIDR
  compartment_id = var.compartment_ocid
  display_name   = "${var.redis-prefix}-vcn"
  dns_label      = var.redis-prefix

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

}

resource "oci_core_internet_gateway" "redis-igw" {
  count          = (!var.use_existing_vcn && !var.use_private_subnet) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.redis-prefix}-igw"
  vcn_id         = oci_core_virtual_network.redis-vcn[0].id

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_nat_gateway" "redis-nat" {
  count          = (!var.use_existing_vcn && var.use_private_subnet) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.redis-prefix}-nat"
  vcn_id         = oci_core_virtual_network.redis-vcn[0].id

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_route_table" "redis-pub-rt" {
  count          = (!var.use_existing_vcn && !var.use_private_subnet) ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.redis-vcn[0].id
  display_name   = "${var.redis-prefix}-pub-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.redis-igw[0].id
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_route_table" "redis-priv-rt" {
  count          = (!var.use_existing_vcn && var.use_private_subnet) ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.redis-vcn[0].id
  display_name   = "${var.redis-prefix}-priv-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.redis-nat[0].id
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_subnet" "redis-subnet" {
  count             = !var.use_existing_vcn ? 1 : 0
  cidr_block        = var.Subnet-CIDR
  display_name      = "${var.redis-prefix}-subnet"
  dns_label         = var.redis-prefix
  security_list_ids = [oci_core_security_list.redis-securitylist[0].id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.redis-vcn[0].id
  route_table_id    = var.use_private_subnet ? oci_core_route_table.redis-priv-rt[0].id : oci_core_route_table.redis-pub-rt[0].id
  dhcp_options_id   = oci_core_virtual_network.redis-vcn[0].default_dhcp_options_id
  prohibit_public_ip_on_vnic = var.use_private_subnet ? true : false

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}
