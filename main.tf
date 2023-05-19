terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.56.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "terra-rg"
      storage_account_name = "tfstatebackup999"
      container_name       = "mytfstatefile"
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {} 
}


variable "prefix" {
  default = "shubh"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = "uk south"
}

resource "azurerm_network_security_group" "my-sg" {
    name = "sg"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    security_rule {
    name                       = "test100"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "test150"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "test200"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  
}
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

}
resource "azurerm_network_interface_security_group_association" "ngs-association" {
  network_interface_id = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.my-sg.id

}
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}
resource "azurerm_public_ip" "example" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
}
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"
  

  ############################## Uncomment this line to delete the OS disk automatically when deleting the VM
  ###################################### delete_os_disk_on_termination = true

  ########################################## Uncomment this line to delete the data disks automatically when deleting the VM
  ################################### delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "devil-vm"
    admin_username = "kosta"
    admin_password = "Shubham@12345"
    custom_data = filebase64("./script.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
# resource "null_resource" "example" {
#   connection {
#     type        = "ssh"
#     host        = azurerm_public_ip.example.ip_address
#     user        = "kosta"
#     password    = "Shubham@12345"
#     timeout     = "10m"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "yes | sudo waagent -deprovision+user"
#     ]
#   }
# }