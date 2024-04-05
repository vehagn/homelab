variable "euclid" {
  description = "Proxmox server configuration for Euclid"
  type        = object({
    node_name = string
    endpoint  = string
    insecure  = bool
  })
}

variable "euclid_auth" {
  description = "Euclid Proxmox server auth"
  type        = object({
    username  = string
    api_token = string
  })
  sensitive = true
}

variable "vm_dns" {
  description = "DNS config for VMs"
  type = object({
    domain = string
    servers = list(string)
  })
}

variable "vm_user" {
  description = "VM username"
  type        = string
}

variable "vm_password" {
  description = "VM password"
  type        = string
  sensitive   = true
}

variable "host_pub-key" {
  description = "Host public key"
  type        = string
}

variable "k8s-version" {
  description = "Kubernetes version"
  type        = string
}

variable "cilium-cli-version" {
  description = "Cilium CLI version"
  type        = string
}
