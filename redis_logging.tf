## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_logging_log_group" "redis_log_group" {
  count          = var.use_redis_oci_logging ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "redis-log-group"
}

resource "oci_logging_log" "redis_log" {
  count              = var.use_redis_oci_logging ? 1 : 0
  display_name       = "redis-logs"
  is_enabled         = true
  log_group_id       = oci_logging_log_group.redis_log_group[0].id
  log_type           = "CUSTOM"
  retention_duration = "30"
}

resource "oci_logging_unified_agent_configuration" "redis_log_agent_config" {
  count          = var.use_redis_oci_logging ? 1 : 0
  compartment_id = var.compartment_ocid
  description    = "Log Agent configuration for Redis nodes"
  display_name   = "redis-log-agent-config"

  group_association {
    group_list = [
      oci_identity_dynamic_group.redis_dynamic_group[0].id
    ]
  }
  is_enabled = true

  service_configuration {

    configuration_type = "LOGGING"

    destination {
      log_object_id = oci_logging_log.redis_log[0].id
    }

    sources {

      name = "redis_server"

      parser {

        parser_type = "REGEXP"
        expression  = "^(?<pid>\\d+):(?<role>[XCSM]) (?<time>[^\\]]*) (?<level>[\\.\\-\\*\\#]) (?<message>.+)$"
        time_format = "%d %B %Y %H:%M:%S.%L"
      }

      paths = [
        "/tmp/redis-server.log"
      ]

      source_type = "LOG_TAIL"
    }
  }
}
