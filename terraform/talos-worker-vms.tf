# Talos worker VMs
resource "azurerm_linux_virtual_machine" "talos_worker" {
  count               = 3
  name                = "talos-worker-big-${count.index}"
  location            = var.location
  resource_group_name = var.group_name
  size                = "Standard_D2s_v5"

  admin_username      = "talos"
  network_interface_ids = [
    azurerm_network_interface.worker_nic[count.index].id
  ]

  source_image_id = data.azurerm_image.custom.id

  # Cloud-init / custom data (worker.yaml)
  custom_data = filebase64("../worker.yaml")

  os_disk {
    name                 = "talos-worker-big-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 80
  }

  admin_ssh_key {
    username   = "talos"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = "https://${var.storage_account}.blob.core.windows.net/"
  }
  depends_on = [
    azurerm_storage_account.talos_sa
  ]
}

resource "azurerm_network_interface" "worker_nic" {
  count               = 3
  name                = "worker-nic-${count.index}"
  location            = var.location
  resource_group_name = var.group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}