## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_bastion_bastion" "bastion_service" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = oci_core_subnet.my_compute_private_subnet.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = "BastionServiceForRedis"
  max_session_ttl_in_seconds   = 10800
}
