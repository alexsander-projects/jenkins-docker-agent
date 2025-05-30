#Here we declare the variable values

#resource group
resource_group = {
  location = "east us"
  name     = "jenkins-rg"
}

#virtual network
virtual_network = {
  address_space = ["10.0.0.0/16"]
  name          = "vnet1"
}

#subnet
subnet = {
  address_prefixes = ["10.0.2.0/24"]
  name             = "subnet1"
}

#public ip
public_ip = {
  agent_ip_name     = "agent_ip"
  master_ip_name    = "master_ip"
  allocation_method = "Static"
}

#network interface
network_interface = {
  ip_configuration_name         = "internal"
  master_nic_name               = "nic1"
  agent_nic_name                = "agent-nic1"
  private_ip_address_allocation = "Dynamic"

}

#network security group
network_security_group = {
  network_security_group_name = "SecurityGroup"
}

#security rule
security_rule = {
  name                       = "test123"
  priority                   = "200"
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "0-65000"
  destination_port_range     = "0-65000"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

#virtual machine(s)
virtual_machines = {
  master_name                     = "mastervm"
  agent_name                      = "agentVm"
  size                            = "Standard_D2s_v3"
  agent_size                      = "Standard_DS1_v2"
  priority                        = "Spot"
  eviction_policy                 = "Deallocate"
  max_bid_price                   = "0.20"
  disable_password_authentication = "false"
}

#vms os disk
os_disk = {
  caching              = "ReadWrite"
  storage_account_type = "Premium_LRS"
}

#vms image
source_image_reference = {
  offer     = "CentOS"
  publisher = "OpenLogic"
  version   = "latest"
  sku       = "8_5-gen2"
}

#vms secrets
vm_secrets = {
  admin_username = "<admin_username>" # Replace with your admin username
}

#vms extension
vm_extension = {
  name                 = "script"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  protected_settings2 = <<PROTECTED_SETTINGS
    {
          "commandToExecute": "sh script2.sh",
          "storageAccountName": "terraformbackend5167",
          "storageAccountKey": "<storageAccountKey>",
          "fileUris": ["<fileUris>"]
    }
 PROTECTED_SETTINGS
  protected_settings   = <<PROTECTED_SETTINGS
    {
          "commandToExecute": "sh script2.sh",
          "storageAccountName": "terraformbackend5167",
          "storageAccountKey": "<storageAccountKey>",
          "fileUris": ["<fileUris>"]
    }
 PROTECTED_SETTINGS

}
