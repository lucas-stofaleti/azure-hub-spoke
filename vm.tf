###    HUB VM    ###
resource "azurerm_network_interface" "hub" {
  count               = length(azurerm_subnet.hub)
  name                = "${local.hub_name}-nic${count.index}"
  location            = var.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hub[count.index].id
  }
}

resource "azurerm_public_ip" "hub" {
  count               = length(azurerm_subnet.hub)
  name                = "${local.hub_name}-pip${count.index}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.hub.location
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_linux_virtual_machine" "hub" {
  count               = length(azurerm_network_interface.hub)
  name                = "${local.hub_name}-vm${count.index}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = var.tags
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.hub[count.index].id,
  ]

  admin_ssh_key {
    username   = var.linux_config.username
    public_key = var.linux_config.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS-GEN2"
    version   = "latest"
  }
}

###   SPOKE VMS  ###
resource "azurerm_network_interface" "spoke" {
  for_each            = local.nics
  name                = "${local.spoke_name}${each.value}-nic${index(keys({ for k, v in local.nics : k => v if v == each.value }), each.key)}"
  location            = azurerm_virtual_network.spoke[each.value].location
  resource_group_name = azurerm_virtual_network.spoke[each.value].resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = tolist(azurerm_virtual_network.spoke[each.value].subnet)[index(keys({ for k, v in local.nics : k => v if v == each.value }), each.key)].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke[each.key].id
  }
}

resource "azurerm_public_ip" "spoke" {
  for_each            = local.nics
  name                = "${local.spoke_name}${each.value}-pip${index(keys({ for k, v in local.nics : k => v if v == each.value }), each.key)}"
  resource_group_name = azurerm_virtual_network.spoke[each.value].resource_group_name
  location            = azurerm_virtual_network.spoke[each.value].location
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_linux_virtual_machine" "spoke" {
  for_each            = local.nics
  name                = replace(azurerm_network_interface.spoke[each.key].name, "nic", "vm")
  resource_group_name = azurerm_network_interface.spoke[each.key].resource_group_name
  location            = azurerm_network_interface.spoke[each.key].location
  tags                = var.tags
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.spoke[each.key].id,
  ]

  admin_ssh_key {
    username   = var.linux_config.username
    public_key = var.linux_config.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS-GEN2"
    version   = "latest"
  }
}