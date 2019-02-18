variable region {
  default = "us-central1"
}

variable zone {
  default = "us-central1-a"
}

variable project {}

variable zk_version {
  description = ""
  default     = "3.4.12"
}

variable kafka_version {
  default = "2.1.0"
}

variable subnet {
  default = "default"
}

variable zkdata_dir {
  default = "/zkdata"
}

variable zk_machine_type {
  default = "n1-standard-1"
}

variable kafka_machine_type {
  default = "n1-standard-2"
}
variable admin_machine_type {
  default = "n1-standard-1"
}
variable kerberos_machine_type {
  default = "n1-standard-2"
}
variable kafka_log_dir {
  default = "/opt/kafka-logs"
}

variable zk_node_count {
  default = 3
}

variable kafka_node_count {
  default = 3
}

variable zk_disk_size{
  default = 10
}
