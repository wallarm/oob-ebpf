variable "name_prefix" {
  default = "ci-oob-ebpf"
}

variable "node_count" {
  default = 1
}

variable "image_type" {
  description = "Worker node image type: COS_CONTAINERD or UBUNTU_CONTAINERD"
}

variable "kube_version" {}

variable "github_run_number" {}
