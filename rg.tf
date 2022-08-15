resource "azurerm_resource_group" "hub" {
  name     = local.hub_name
  location = var.hub.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke" {
  count    = length(var.spoke)
  name     = "${local.spoke_name}-${count.index}"
  location = var.spoke[count.index].location
  tags     = var.tags
}