# Upload VHD blob (local file to storage)
resource "azurerm_storage_blob" "vhd" {
  name                   = "talos-azure.vhd"
  storage_account_name   = azurerm_storage_account.talos_sa.name
  storage_container_name = azurerm_storage_container.talos_container.name
  type                   = "Page"
  source                 = "../images/azure-amd64.vhd"   # local file to upload
}


resource "time_sleep" "wait_65_seconds" {
  depends_on = [azurerm_storage_blob.vhd]

  create_duration = "65s"
}

# Create image from blob
resource "azurerm_image" "talos" {
  name                = "talos"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = azurerm_storage_blob.vhd.url
    storage_type = "Standard_LRS"
  }

  depends_on = [time_sleep.wait_65_seconds]
}