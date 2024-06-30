variable "sealed_secrets_cert" {
  type = object({
    cert = string
    key = string
  })
}