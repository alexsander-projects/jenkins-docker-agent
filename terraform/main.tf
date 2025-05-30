terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.65.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.3.2"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {
}

#Resource Group
resource "azurerm_resource_group" "jenkins-rg" {
  name     = var.resource_group.name
  location = var.resource_group.location
}

#Virtual network
resource "azurerm_virtual_network" "jenkins-vnet" {
  name                = var.virtual_network.name
  address_space       = var.virtual_network.address_space
  location            = azurerm_resource_group.jenkins-rg.location
  resource_group_name = azurerm_resource_group.jenkins-rg.name
  depends_on          = [azurerm_resource_group.jenkins-rg]
}

#Subnet
resource "azurerm_subnet" "jenkins-subnet" {
  name                 = var.subnet.name
  resource_group_name  = azurerm_resource_group.jenkins-rg.name
  virtual_network_name = azurerm_virtual_network.jenkins-vnet.name
  address_prefixes     = var.subnet.address_prefixes
  depends_on           = [azurerm_virtual_network.jenkins-vnet]
}

#Network Security Group
resource "azurerm_network_security_group" "jenkins-nsg" {
  name                = var.network_security_group.network_security_group_name
  location            = azurerm_resource_group.jenkins-rg.location
  resource_group_name = azurerm_resource_group.jenkins-rg.name
  security_rule {
    name                       = var.security_rule.name
    priority                   = var.security_rule.priority
    direction                  = var.security_rule.direction
    access                     = var.security_rule.access
    protocol                   = var.security_rule.protocol
    source_port_range          = var.security_rule.source_port_range
    destination_port_range     = var.security_rule.destination_port_range
    source_address_prefix      = var.security_rule.source_address_prefix
    destination_address_prefix = var.security_rule.destination_address_prefix
  }
}

#Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "jenkins-nsg-asc" {
  subnet_id                 = azurerm_subnet.jenkins-subnet.id
  network_security_group_id = azurerm_network_security_group.jenkins-nsg.id
  depends_on                = [azurerm_network_security_group.jenkins-nsg]
}

#Public Ip Master
resource "azurerm_public_ip" "master-ip" {
  name                = var.public_ip.master_ip_name
  resource_group_name = azurerm_resource_group.jenkins-rg.name
  location            = azurerm_resource_group.jenkins-rg.location
  allocation_method   = var.public_ip.allocation_method
  depends_on          = [azurerm_subnet.jenkins-subnet]
}

#Network Interface Master
resource "azurerm_network_interface" "master_nic" {
  name                = var.network_interface.master_nic_name
  location            = azurerm_resource_group.jenkins-rg.location
  resource_group_name = azurerm_resource_group.jenkins-rg.name

  ip_configuration {
    name                          = var.network_interface.ip_configuration_name
    subnet_id                     = azurerm_subnet.jenkins-subnet.id
    private_ip_address_allocation = var.network_interface.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.master-ip.id
  }
  depends_on = [azurerm_public_ip.master-ip]
}

#Public Ip Agent
resource "azurerm_public_ip" "agentip" {
  name                = var.public_ip.agent_ip_name
  resource_group_name = azurerm_resource_group.jenkins-rg.name
  location            = azurerm_resource_group.jenkins-rg.location
  allocation_method   = var.public_ip.allocation_method
}

#Network Interface Agent
resource "azurerm_network_interface" "agentnic" {
  name                = var.network_interface.agent_nic_name
  location            = azurerm_resource_group.jenkins-rg.location
  resource_group_name = azurerm_resource_group.jenkins-rg.name

  ip_configuration {
    name                          = var.network_interface.ip_configuration_name
    subnet_id                     = azurerm_subnet.jenkins-subnet.id
    private_ip_address_allocation = var.network_interface.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.agentip.id
  }
}

#Linux Virtual Machine Master
resource "azurerm_linux_virtual_machine" "masterVm" {
  name                            = "master${random_string.masterVm.result}"
  resource_group_name             = azurerm_resource_group.jenkins-rg.name
  location                        = azurerm_resource_group.jenkins-rg.location
  size                            = var.virtual_machines.size
  priority                        = var.virtual_machines.priority
  eviction_policy                 = var.virtual_machines.eviction_policy
  max_bid_price                   = var.virtual_machines.max_bid_price
  admin_username                  = var.vm_secrets.admin_username
  admin_password                  = random_password.masterpassword.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.master_nic.id,
  ]
  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }
  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }
}

#Virtual Machine Extension
resource "azurerm_virtual_machine_extension" "masterVm" {
  name                 = var.vm_extension.name
  virtual_machine_id   = azurerm_linux_virtual_machine.masterVm.id
  publisher            = var.vm_extension.publisher
  type                 = var.vm_extension.type
  type_handler_version = var.vm_extension.type_handler_version
  protected_settings   = jsonencode({
    script           = base64encode(file("../script.sh")) // Assumes script.sh is in the parent directory
  })
  depends_on           = [azurerm_linux_virtual_machine.masterVm]
}

#Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "agentVm2" {
  name                            = "agent${random_string.agentVm.result}"
  resource_group_name             = azurerm_resource_group.jenkins-rg.name
  location                        = azurerm_resource_group.jenkins-rg.location
  size                            = var.virtual_machines.agent_size
  priority                        = var.virtual_machines.priority
  eviction_policy                 = var.virtual_machines.eviction_policy
  max_bid_price                   = var.virtual_machines.max_bid_price
  admin_username                  = var.vm_secrets.admin_username
  admin_password                  = random_password.agentpassword.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.agentnic.id,
  ]
  os_disk {
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }
  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }
  depends_on = [azurerm_public_ip.agentip]
}

#Virtual Machine Extension
resource "azurerm_virtual_machine_extension" "agentVm" {
  name                 = var.vm_extension.name
  virtual_machine_id   = azurerm_linux_virtual_machine.masterVm.id
  publisher            = var.vm_extension.publisher
  type                 = var.vm_extension.type
  type_handler_version = var.vm_extension.type_handler_version
  protected_settings   = jsonencode({
    script           = base64encode(file("../script2.sh")) // Assumes script2.sh is in the parent directory
  })
  depends_on           = [azurerm_linux_virtual_machine.masterVm]
}

#Random string
resource "random_string" "masterVm" {
  length  = 4
  numeric = true
  upper   = false
  lower   = false
  special = false
}

#Random string
resource "random_string" "agentVm" {
  length  = 4
  numeric = true
  upper   = false
  lower   = false
  special = false
}

resource "random_password" "masterpassword" {
  length  = 16
  special = false
  numeric = true
  upper   = true
  lower   = true
}

resource "random_password" "agentpassword" {
  length  = 16
  special = false
  numeric = true
  upper   = true
  lower   = true
}
