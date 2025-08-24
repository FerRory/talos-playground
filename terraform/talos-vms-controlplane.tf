
resource "azurerm_linux_virtual_machine" "controlplane" {
  count               = 3
  name                = "talos-controlplane-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  size                = "Standard_D2s_v5"
  admin_username      = "talos"
  network_interface_ids = [
    azurerm_network_interface.controlplane[count.index].id
  ]
  availability_set_id = azurerm_availability_set.controlplane.id

  admin_ssh_key {
    username   = "talos"
    public_key = file("~/.ssh/id_rsa.pub") # adjust if needed
  }
  source_image_id = azurerm_image.talos.id
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 20
  }



  custom_data = filebase64("../secrets/controlplane.yaml") # cloud-init user data
  boot_diagnostics {
    storage_account_uri = "https://${var.storage_account}.blob.core.windows.net/"
  }
  depends_on = [
    azurerm_storage_account.talos_sa,
    azurerm_image.talos
  ]
}

# Create 3 Control Plane NICs with Public IPs and attach to LB backend pool
resource "azurerm_public_ip" "controlplane" {
  count               = 3
  name                = "talos-controlplane-public-ip-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "controlplane" {
  count               = 3
  name                = "talos-controlplane-nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.controlplane[count.index].id
   
  }
}


