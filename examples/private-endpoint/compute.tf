resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "jumper" {
  location            = azurerm_resource_group.this.location
  name                = "example-nic"
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet.vnet_subnets_name_id["subnet0"]
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  admin_username = "adminuser"
  location       = azurerm_resource_group.this.location
  name           = "example-machine"
  network_interface_ids = [
    azurerm_network_interface.jumper.id,
  ]
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_F2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    public_key = tls_private_key.key.public_key_openssh
    username   = "adminuser"
  }
  source_image_reference {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "Canonical"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "local_sensitive_file" "private_key" {
  filename = "${path.module}/key.pem"
  content  = tls_private_key.key.private_key_openssh
}