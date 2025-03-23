variable "cert" {
  type = object({
    certificate_path = string
    certificate_key_path = string
  })
}
