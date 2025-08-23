





data "azurerm_image" "custom" {
  name                = "talos"
  resource_group_name = "talos"
}



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
  source_image_id = data.azurerm_image.custom.id
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 20
  }



  custom_data = filebase64("../controlplane.yaml") # cloud-init user data
  boot_diagnostics {
    storage_account_uri = "https://${var.storage_account}.blob.core.windows.net/"
  }
  depends_on = [
    azurerm_storage_account.talos_sa
  ]
}

resource "azurerm_network_interface" "controlplane" {
  count               = 3
  name                = "talos-controlplane-nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "controlplane" {
  name                         = "talos-controlplane-av-set"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_update_domain_count = 5
  platform_fault_domain_count  = 2
  managed                      = true
}

# Example VNet + Subnet (if you don’t already have one)
resource "azurerm_virtual_network" "main" {
  name                = "talos-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "talos-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}