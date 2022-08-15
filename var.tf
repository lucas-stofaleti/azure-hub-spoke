variable "hub" {
  description = "Hub Network Configuration"
  type = object({
    cidr     = list(string)
    subnets  = list(string)
    location = string
    firewall = object({
      cidr = string
    })
  })
}

variable "spoke" {
  description = "Spoke Network Configuration"
  type = list(object({
    cidr     = list(string)
    subnets  = list(string)
    location = string
  }))
}

variable "tags" {
  default = {
    "Terraform" = "true"
  }
  type        = map(string)
  description = "Tags for resources"
}

variable "name" {
  type        = string
  description = "Name for resources"
}

variable "linux_config" {
  type = object({
    username   = string
    public_key = string
  })
}

locals {
  hub_name   = "${var.name}-hub"
  spoke_name = "${var.name}-spoke"
}

locals {
  nics = merge([for vnet in var.spoke : { for subnet in vnet.subnets : subnet => index(var.spoke, vnet) }]...)
}

# output "nic" {
#   value = local.list
# }

# output "nics" {
#   value = local.nics
# }