variable "cluster" {
  type = object({
    name = string
  })
  default = {
    name = "talos"
  }
}

variable "k8s-ctrl-00" {
  description = "Node Settings"
  type        = object({
    hostname    = string
    ip          = string
    mac_address = string
  })
}

#variable "k8s-ctrl-01" {
#  description = "Node Settings"
#  type        = object({
#    hostname    = string
#    ip          = string
#    mac_address = string
#  })
#}

#variable "k8s-version" {
#  description = "Kubernetes version"
#  type        = string
#}
#
#variable "cilium-cli-version" {
#  description = "Cilium CLI version"
#  type        = string
#}
