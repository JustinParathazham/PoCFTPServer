variable "default_tags" {
  description = "Default set of tags to apply to all resources"
  type = map(string)
  default = {
    AppName = "enr-totalflex-D"
    Branch = "TS"
    Environment = "D"
    "Maintenance Window" = "default"
    "OpeningTime" = "default"
    "Exploitation" = "default"
    "Security Level" = "Standard"
  }
}