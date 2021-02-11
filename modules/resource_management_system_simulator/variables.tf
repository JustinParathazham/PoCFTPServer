variable "vpc_cidr" {
  description = "CIDR block for the RMS block"
  type        = string
  default     = "10.45.0.0/16"
}

variable "ami_id" {
  description = "The id of the AMI to used as asset simulator"
  type        = string
}

variable "instance_type" {
  description = "The instance type that is to be used as asset."
  type        = string
  default     = "t2.micro"
}

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

variable "admin_public_key" {
  description = "OpenSSH formatted public key used for administration of the pfsense"
  type        = string
}

variable "admin_key_pair_name" {
  description = "The name of the key allowing connection to the VM"
  type        = string
}

variable "edge_cidr" {
  description = "The CIDR of the Edge VPC"
  type        = string
}

variable "asset_cidrs" {
  description = "The list of CIDRs associated with the remote assets"
  type        = list(string)
}

variable "enr_spoke_vpc_cidr" {
  description = "CIDR block of the ENR Spoke VPC"
  type        = string
}

variable "tags" {
  description = "Tags to set on the resources"
  type        = map(string)
}

variable "edge_tgw_attachment" {
  description = "Attachment of the Edge VPC to the RMS Transit Gateway"
  type        = object({id=string})
}

variable "trusted_source_cidrs" {
  description = "The list of CIDRs from which user and admin access is permitted"
  type        = list(string)
}