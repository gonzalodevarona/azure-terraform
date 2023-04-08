terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg"
  location = "East US"
}

resource "azurerm_storage_account" "storageaccountterramelo1" {
  name                     = "storageaccountterramelo1"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "sp" {
  name                = "sp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"

  sku_name = "Y1"
}

resource "azurerm_windows_function_app" "wfa" {
  name                = "function-app-remelit4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  storage_account_name       = azurerm_storage_account.storageaccountterramelo1.name
  storage_account_access_key = azurerm_storage_account.storageaccountterramelo1.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id

  site_config {
    application_stack {
      node_version = "~16"
    }
  }
}

resource "azurerm_function_app_function" "faf" {
  name            = "faf"
  function_app_id = azurerm_windows_function_app.wfa.id
  language        = "Javascript"
  # Se carga el código de ejemplo dentro de la función
  file {
    name    = "index.js"
    content = file("example/index.js")
  }
  # Se define el payload para los test
  test_data = jsonencode({
    "name" = "Azure"
  })
  # Se mapean las solicitudes
  config_json = jsonencode({
    "bindings": [
        {
        "authLevel": "anonymous",
        "type": "httpTrigger",
        "direction": "in",
        "name": "req",
        "methods": [
            "get",
            "post"
        ]
        },
        {
        "type": "http",
        "direction": "out",
        "name": "res"
        }
    ]
    })
}