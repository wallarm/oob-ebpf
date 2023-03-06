variable "name_prefix" {
  default = "github-ci-oob-ebpf"
}

variable "location" {
  default = "UK South"
}

variable "node_count" {
  default = 1
}

variable "node_size" {
  default = "Standard_D4s_v3"
}

variable "kube_version" {}

variable "github_run_id" {}

variable "github_run_number" {}
