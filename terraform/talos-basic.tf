variable "group_name" {
  type    = string
  default = "tf-talos" # replace with your resource group
}
variable "location" {
  type    = string
  default = "westeurope"
}

variable "storage_account" {
  type    = string
  default = "brtalosstorage" # replace with your storage account
}

variable "storage_container" {
  type    = string
  default = "talos-image" # replace with your storage account
}


resource "azurerm_resource_group" "main" {
  name     = var.group_name
  location = var.location
}
