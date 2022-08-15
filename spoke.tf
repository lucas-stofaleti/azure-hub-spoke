resource "azurerm_virtual_network" "spoke" {
  count               = length(var.spoke)
  name                = "${local.spoke_name}${count.index}-vnet"
  location            = var.spoke[count.index].location
  resource_group_name = azurerm_resource_group.spoke[count.index].name
  address_space       = var.spoke[count.index].cidr
  tags                = var.tags

  dynamic "subnet" {
    for_each = var.spoke[count.index].subnets
    content {
      name           = "${local.spoke_name}${count.index}-subnet${index(var.spoke[count.index].subnets, subnet.value)}"
      address_prefix = subnet.value
      security_group = azurerm_network_security_group.spoke[count.index].id
    }
  }
}

resource "azurerm_route_table" "spoke" {
  count                         = length(var.spoke)
  name                          = "${local.spoke_name}${count.index}-rt"
  location                      = var.spoke[count.index].location
  resource_group_name           = azurerm_resource_group.spoke[count.index].name
  disable_bgp_route_propagation = false

  dynamic "route" {
    for_each = { for vnet in var.spoke : vnet.cidr[0] => index(var.spoke, vnet) if vnet.cidr[0] != var.spoke[count.index].cidr[0] }
    content {
      name                   = route.value
      address_prefix         = route.key
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
    }
  }
  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "spoke" {
  for_each       = local.nics
  subnet_id      = tolist(azurerm_virtual_network.spoke[each.value].subnet)[index(keys({ for k, v in local.nics : k => v if v == each.value }), each.key)].id
  route_table_id = azurerm_route_table.spoke[each.value].id
}

resource "azurerm_network_security_group" "spoke" {
  count               = length(var.spoke)
  name                = "${local.spoke_name}${count.index}-sg"
  location            = var.spoke[count.index].location
  resource_group_name = azurerm_resource_group.spoke[count.index].name
  tags                = var.tags
  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}



resource "azurerm_virtual_network_peering" "spoke-hub" {
  count                        = length(var.spoke)
  name                         = "spoke${count.index}-hub"
  resource_group_name          = azurerm_resource_group.spoke[count.index].name
  virtual_network_name         = azurerm_virtual_network.spoke[count.index].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}