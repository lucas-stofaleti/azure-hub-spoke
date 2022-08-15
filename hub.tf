resource "azurerm_virtual_network" "hub" {
  name                = "${local.hub_name}-vnet"
  location            = var.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.hub.cidr
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  count                = length(var.hub.subnets)
  name                 = "${local.hub_name}-subnet${count.index}"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub.subnets[count.index]]
  service_endpoints    = []
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub.firewall.cidr]
  service_endpoints    = []
}

resource "azurerm_firewall_policy" "hub" {
  name                = "${local.hub_name}-firewallpolicy"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
}

resource "azurerm_firewall" "hub" {
  name                = "${local.hub_name}-firewall"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_public_ip" "firewall" {
  name                = "${local.hub_name}-pip-firewall"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "hub" {
  name               = "${local.hub_name}-rule-firewall"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 500

  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 400
    action   = "Allow"
    rule {
      name                  = "spoke2spoke"
      protocols             = ["Any"]
      source_addresses      = flatten([for vnet in var.spoke : vnet.cidr])
      destination_addresses = flatten([for vnet in var.spoke : vnet.cidr])
      destination_ports     = ["*"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "hub" {
  count                     = length(azurerm_subnet.hub)
  subnet_id                 = azurerm_subnet.hub[count.index].id
  network_security_group_id = azurerm_network_security_group.hub.id
}

resource "azurerm_network_security_group" "hub" {
  name                = "${local.hub_name}-sg"
  location            = var.hub.location
  resource_group_name = azurerm_resource_group.hub.name
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

resource "azurerm_virtual_network_peering" "hub-spoke" {
  count                        = length(var.spoke)
  name                         = "hub-spoke${count.index}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[count.index].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}