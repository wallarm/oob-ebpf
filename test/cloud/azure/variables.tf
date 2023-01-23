variable "name_prefix" {
  default = "github-ci-oob-ebpf"
}

variable "location" {
  default = "UK South"
}

variable "node_count" {
  default = 1
}

variable "kube_version" {}

variable "github_run_id" {}

variable "github_run_number" {}
