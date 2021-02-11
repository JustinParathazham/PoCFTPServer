variable "application_code" {
  description = "The 4 letter code of the application. This is used to compile the resources names"
  type        = string
}

variable "index" {
  description = "The 2 digit index of the component. This is used to compile the resources names"
  type        = number
}

variable "environment" {
  description = "The 1 character environment notation: {p, a, q, i, d, y, s}. This is used to compile the resources names"
  type        = string
}

variable "tags" {
  description = "Tags to set on the resources"
  type        = map(string)
}

variable "secrets_manager_prefix" {
  description = "Prefix to be used to store secrets manager keys"
  type        = string
}

variable "secrets_recovery_window" {
  description = "The number of days that a secrets can be recovered from. Can be 0 (immediate deletion) or range from 7 to 30. It is recommended to set up to 0 for development only"
  type        = number
  default     = 30
}

variable "tunnel_configs" {
  description = "Object containing the tunnel configurations to be created. This is used to generate and securely store the PSKs"
  type        = object({ipsec_tunnels=map(any)})
  default     = {ipsec_tunnels={}}
}