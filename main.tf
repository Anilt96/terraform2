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

resource "azurerm_resource_group" "main" {
    name     = "resources"
    location = "South India"
}

resource "azurerm_virtual_network" "main" {
    name                 = "network"
    address_space        = ["10.0.0.0/16"]
    location             = "South India"
    resource_group_name  = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
    name                 = "internal"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main" {
    name             = "sg"
    location         = "South India"
    resource_group_name = azurerm_resource_group.main.name

    security_rule {
        name                        = "HTTP"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "8080"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
    security_rule {
        name                        = "SSH"
        priority                    = 101
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }

}

resource "azurerm_network_interface" "main" {
    name                = "nic"
    location            = "South India"
    resource_group_name = azurerm_resource_group.main.name
    ip_configuration {
        name                       = "testconfiguration1"
        subnet_id                  =  azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.main.id
    }
}

resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id            = azurerm_network_interface.main.id
    network_security_group_id       = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main" {
    name                    = "ip"
    location                = "South India"
    resource_group_name     = azurerm_resource_group.main.name
    allocation_method       = "Dynamic"
    domain_name_label       = "jenkins"
}

resource "azurerm_virtual_machine" "main" {
    name                              = "vm"
    location                          = azurerm_resource_group.main.location
    resource_group_name               = azurerm_resource_group.main.name
    network_interface_ids             = azurerm_network_interface.main.id
    vm_size                           = "Standard_B2ms"

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
    storage_os_disk {
        name          = "myosdisk1"
        caching       = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    os_profile {
        computer_name    = "${var.hostname}"
        admin_username   = "adminuser1"
        admin_password   = "admin@1234"
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }

    provisioner "remote-exec" {
        connection {
            host     = azurerm_public_ip.main.fqdn
            type     = "ssh"
            user     = "adminuser1"
            password = "admin@1234"
        }
        inline = [
            "sudo wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
            "sudo chmod 777 /etc/apt/sources.list",
            "sudo echo 'deb http://pkg.jenkins.io/debian-stable binary/' >> /etc/apt/sources.list",
            "sudo apt-get update",
            "sudo apt-get install -y jenkins=2.32.1",
            "cd /usr/share/jenkins",
            "sudo service jenkins stop",
            "sudo mv jenkins.war jenkins.war.old",
            "sudo wget https://updates.jenkins-ci.org/latest/jenkins.war",
            "sudo service jenkins start",
            "cd  ",
            "sudo curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
            "sudo wget https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip",
            "sudo apt-get install -y unzip",
            "sudo unzip terraform_0.13.3_linux_amd64.zip",
            "sudo cp terraform /usr/bin/",
            "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
        ]
    }

}
