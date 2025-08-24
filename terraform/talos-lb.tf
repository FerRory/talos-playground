# Public IP for Load Balancer
resource "azurerm_public_ip" "talos_lb" {
  name                = "talos-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Load Balancer
resource "azurerm_lb" "talos" {
  name                = "talos-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "talos-fe"
    public_ip_address_id = azurerm_public_ip.talos_lb.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "talos" {
  name                = "talos-be-pool"
  loadbalancer_id     = azurerm_lb.talos.id
}

# Health Probe
resource "azurerm_lb_probe" "talos" {
  name                = "talos-lb-health"
  loadbalancer_id     = azurerm_lb.talos.id
  protocol            = "Tcp"
  port                = 6443
}

# Load Balancer Rule
resource "azurerm_lb_rule" "talos_6443" {
  name                           = "talos-6443"
  loadbalancer_id                = azurerm_lb.talos.id
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "talos-fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.talos.id]
  probe_id                       = azurerm_lb_probe.talos.id
}


resource "azurerm_network_interface_backend_address_pool_association" "talos" {
  count                   = 3
  network_interface_id    = azurerm_network_interface.controlplane[count.index].id
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.talos.id
}

