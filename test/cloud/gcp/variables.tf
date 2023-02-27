variable "name_prefix" {
  default = "ci-oob-ebpf"
}

variable "node_count" {
  default = 1
}

variable "os" {
  description = "COS or Ubuntu"
}

variable "kube_version" {}

variable "github_run_number" {}
