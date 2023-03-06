variable "name_prefix" {
  default = "ci-oob-ebpf"
}

variable "node_count" {
  default = 2
}

variable "node_size" {
  default = "e2-medium"
}

variable "os" {
  description = "COS or Ubuntu"
}

variable "kube_version" {}

variable "github_run_number" {}
