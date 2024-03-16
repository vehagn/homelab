variable "euclid" {
  description = "Proxmox server configuration for Euclid machine"
  type        = object({
    node_name = string
    endpoint  = string
    insecure  = bool
  })
}

variable "euclid_auth" {
  description = "Auth for euclid proxmox server"
  type        = object({
    agent     = bool
    username  = string
    api_token = string
  })
  sensitive = true
}

variable "vm_user" {
  description = "vm username"
  type        = string
}

variable "vm_pub-key" {
  description = "vm username"
  type        = string
}

variable "k8s-version" {
  description = "Kubernetes version"
  type = string
}

variable "cilium-cli-version" {
  description = "Cilium CLI version"
  type = string
}
