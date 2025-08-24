# Storage Account
resource "azurerm_storage_account" "talos_sa" {
  name                     = var.storage_account
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  access_tier = "Hot"
}

# Storage Container
resource "azurerm_storage_container" "talos_container" {
  name                  = var.storage_container
  storage_account_id    = azurerm_storage_account.talos_sa.id
  container_access_type = "private"
}