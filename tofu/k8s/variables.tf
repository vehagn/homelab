variable "vm_dns" {
  description = "DNS config for VMs"
  type        = object({
    domain  = string
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

variable "k8s-ctrl-01" {
  description = "Node Settings"
  type        = object({
    hostname    = string
    ip          = string
    mac_address = string
  })
  default = {
    hostname    = "k8s-ctrl-02"
    ip          = "192.168.1.100/24"
    mac_address = "BC:24:11:2E:C0:01"
  }
}

variable "k8s-ctrl-02" {
  description = "Node Settings"
  type        = object({
    hostname    = string
    ip          = string
    mac_address = string
  })
  default = {
    hostname    = "k8s-ctrl-02"
    ip          = "192.168.1.100/24"
    mac_address = "BC:24:11:2E:C0:02"
  }
}

variable "k8s-version" {
  description = "Kubernetes version"
  type        = string
}

variable "cilium-cli-version" {
  description = "Cilium CLI version"
  type        = string
}
