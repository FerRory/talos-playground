


resource "azurerm_network_security_group" "talos_sg" {
  name                = "talos-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

# Client -> apid
resource "azurerm_network_security_rule" "apid" {
  name                        = "apid"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.talos_sg.name
}

# Trustd
resource "azurerm_network_security_rule" "trustd" {
  name                        = "trustd"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50001"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.talos_sg.name
}

# etcd
resource "azurerm_network_security_rule" "etcd" {
  name                        = "etcd"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["2379", "2380"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.talos_sg.name
}

# Kubernetes API Server
resource "azurerm_network_security_rule" "kube" {
  name                        = "kube"
  priority                    = 1004
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.talos_sg.name
}
# NSG association
resource "azurerm_subnet_network_security_group_association" "talos_assoc" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.talos_sg.id
}