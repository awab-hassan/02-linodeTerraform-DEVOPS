variable "token" {
  description = "Linode API token"
  sensitive   = true
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file downloaded after cluster creation"
}

variable "k8s_version" {
  description = "Kubernetes version for LKE cluster"
  default     = "1.24"
}

variable "label" {
  description = "Cluster label"
  default     = "default-lke"
}

variable "region" {
  description = "Linode region"
  default     = "us-east"
}

variable "tags" {
  description = "Cluster tags"
  default     = ["dev"]
}

variable "pools" {
  description = "Node pool configuration"
  default = [
    {
      type  = "g6-standard-2"
      count = 3
    }
  ]
}

variable "mongo_root_username" {
  description = "MongoDB root username"
  sensitive   = true
}

variable "mongo_root_password" {
  description = "MongoDB root password"
  sensitive   = true
}
