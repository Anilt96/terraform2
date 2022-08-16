terraform {
  required_providers {
    azurerm= {
        source = "hashicorp/azurerm"
        version = "2.99.0"
    }
  }
}


provider "azurerm" {
    features{}
}

resource "azurerm_resource_group" "rg" {
    name = "terraform-rg"
    location = "southindia"
}

resource "azurerm_virtual_network" "myvnet" {
  name = "my-vnet"
  address_space = ["10.0.0.0/16"]
  location ="southindia"
  resource_group_name =azurerm_resource_group.rg.name  
}

 resource "azurerm_subnet" "frontendsubnet" {
     name = "frontend-subnet"
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_name = azurerm_virtual_network.myvnet.name
     address_prefixes = ["10.0.1.0/24"]
 }

resource "azurerm_public_ip" "myvm1publicip" {
    name = "pip1"
    location = "southindia"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Dynamic"
    sku = "BAsic"
}

resource "azurerm_network_interface" "myvm1nic" {
    name = "myvm1-nic"
    location = "southindia"
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
      name ="ipconfig1"
      subnet_id =azurerm_subnet.frontendsubnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.myvm1publicip.id
      }
}

resource "azurerm_windows_virtual_machine" "example" {
    name = "myvm1"
    location = "southindia"
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [ azurerm_network_interface.myvm1nic.id ]
    size                = "Standard_F2"
    admin_username = "adminuser"
    admin_password = "password123!"

        source_image_reference {
      publisher ="MicrosoftWindowsServer"
      offer ="windowsServer"
      sku ="2019-Datacenter"
      version ="Latest"
    }

    os_disk {
      caching ="ReadWrite"
      storage_account_type ="Standard_LRS"

    }
  
}
resource "azurerm_subnet" "subnet2" {
     name = "frontend-subnet2"
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_name = azurerm_virtual_network.myvnet.name
     address_prefixes = ["10.0.2.0/24"]
 }


resource "azurerm_network_interface" "myvm2nic" {
    name = "myvm2-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
      name ="ipconfig2"
      subnet_id =azurerm_subnet.subnet2.id
      private_ip_address_allocation = "Dynamic"
      }
}

resource "azurerm_windows_virtual_machine" "vm2" {
    name = "myvm2"
    location = "southindia"
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [ azurerm_network_interface.myvm2nic.id ]
    size = "Standard_B1s"
    admin_username = "adminuser4"
    admin_password = "password123!4"

    source_image_reference {
      publisher ="MicrosoftWindowsServer"
      offer ="windowsServer"
      sku ="2019-Datacenter"
      version ="Latest"
    }

    os_disk {
      caching ="ReadWrite"
      storage_account_type ="Standard_LRS"

    }
  
}