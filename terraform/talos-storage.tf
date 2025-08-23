# Storage Account
resource "azurerm_storage_account" "talos_sa" {
  name                     = var.storage_account
  resource_group_name      = var.group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  access_tier = "Hot"
}

# Storage Container
resource "azurerm_storage_container" "talos_container" {
  name                  = var.storage_container
  storage_account_name  = azurerm_storage_account.talos_sa.name
  container_access_type = "private"
}