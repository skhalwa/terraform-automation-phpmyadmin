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
    # custom_data = filebase64("./script.sh")
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


# ############################################### resource "azurerm_shared_image_gallery" "example" {
# ###############################################   name                = "example_image_gallery"
# ###############################################   resource_group_name = azurerm_resource_group.example.name
# ###############################################   location            = azurerm_resource_group.example.location
# ###############################################   description         = "Shared images and things."
# ##############################################
# ############################################### }
# ##############################################
# ############################################### resource "azurerm_shared_image" "example" {
# ###############################################   name                = "my-image"
# ###############################################   gallery_name        = azurerm_shared_image_gallery.example.name
# ###############################################   resource_group_name = azurerm_resource_group.example.name
# ###############################################   location            = azurerm_resource_group.example.location
# ###############################################   os_type             = "Linux"
# ##############################################
# ###############################################   identifier {
# ###############################################     publisher = "PublisherName"
# ###############################################     offer     = "OfferName"
# ###############################################     sku       = "ExampleSku"
# ###############################################   }
# ############################################### }

resource "azurerm_image" "example" {
  name                      = "acctest"
  location                  = azurerm_resource_group.example.location
  resource_group_name       = azurerm_resource_group.example.name
  source_virtual_machine_id = azurerm_virtual_machine.main.id
}

resource "azurerm_public_ip" "lb-ip" {
  name                = "my-lb-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                          = "PublicIPAddress"
    public_ip_address_id          = azurerm_public_ip.lb-ip.id
  }
}

resource "azurerm_lb_probe" "example" {
  name                = "healthProbe"
  loadbalancer_id     = azurerm_lb.example.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id     = azurerm_lb.example.id
  name                = "backendPool"
}

########################################## resource "azurerm_lb_rule" "example" {
##########################################   resource_group_name            = azurerm_resource_group.example.name
##########################################   loadbalancer_id                = azurerm_lb.example.id
##########################################   name                           = "example-rule"
##########################################   protocol                       = "Tcp"
##########################################   frontend_port                  = 80
##########################################   backend_port                   = 8080
##########################################   backend_address_pool_id        = azurerm_lb_backend_address_pool.example.id
##########################################   probe_id                       = azurerm_lb_probe.example.id
##########################################   enable_floating_ip              = false
##########################################   load_distribution              = "Default"
##########################################   idle_timeout_in_minutes        = 15
########################################## }
resource "azurerm_lb_rule" "example" {
  name                           = "example-rule"
  loadbalancer_id                = azurerm_lb.example.id
  frontend_ip_configuration_name = azurerm_lb.example.frontend_ip_configuration[0].name
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example.id
  protocol                       = "Tcp"
  enable_floating_ip             = false
  load_distribution              = "Default"
  idle_timeout_in_minutes        = 15
}
####################################################################################
resource "azurerm_virtual_network" "vmss-vnet" {
  name                = "vmss-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vmss-subnet" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vmss-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vmss-nsg" {
  name                = "vmss-nsg"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.vmss-subnet.id
  network_security_group_id = azurerm_network_security_group.vmss-nsg.id
}
# Create a virtual machine scale set using the custom image
resource "azurerm_virtual_machine_scale_set" "example" {
  name = "vmss-with-linuxs"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    name     = "Standard_DS1_v2"
    capacity = 1
  }
  
  storage_profile_image_reference {
    id = azurerm_image.example.id
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name_prefix = "linux-vmss"
    admin_username       = "kosta"
    admin_password       = "Shubham@12345"
  }

  upgrade_policy_mode = "Automatic"

  network_profile {
    name    = "example-nic"
    primary = true

    ip_configuration {
      name                          = "example-ipconfig"
      subnet_id                     = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
      primary = true
    }
    network_security_group_id = azurerm_network_security_group.my-sg.id
  }

  
######################################   automatic_redeployment_policy {
######################################     name = "custom-scale-policy"
#####################################
######################################     rules {
######################################       metric_trigger {
######################################         metric_name        = "Percentage CPU"
######################################         metric_resource_id = azurerm_virtual_machine_scale_set.example.id
######################################         time_grain         = "PT1M"
######################################         statistic          = "Average"
######################################         time_window        = "PT5M"
######################################         operator           = "GreaterThan"
######################################         threshold          = 75.0
######################################       }
######################################       scale_action {
######################################         cooldown     = "PT5M"
######################################         direction    = "Increase"
######################################         type         = "ChangeCount"
######################################         value        = "1"
######################################       }
######################################     }
######################################   }
}


