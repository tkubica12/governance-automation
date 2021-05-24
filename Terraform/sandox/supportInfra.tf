// Get random string for suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "azurerm_resource_group" "budgets" {
  name     = "budgets"
  location = "West Europe"
}

// Prepare storage account, container and token, upload code
resource "azurerm_storage_account" "budgets" {
  name                     = "budgets${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.budgets.name
  location                 = azurerm_resource_group.budgets.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "budgets_code_container" {
  name                  = "code"
  storage_account_name  = azurerm_storage_account.budgets.name
  container_access_type = "private"
}

data "azurerm_storage_account_sas" "storage_sas" {
  connection_string = azurerm_storage_account.budgets.primary_connection_string
  https_only        = false
  resource_types {
    service   = false
    container = false
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  start  = "2021-01-01"
  expiry = "2031-01-01"
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

resource "azurerm_storage_blob" "code" {
  name                   = "automationFunctions.zip"
  storage_account_name   = azurerm_storage_account.budgets.name
  storage_container_name = azurerm_storage_container.budgets_code_container.name
  type                   = "Block"
  source                 = "automationFunctions.zip"
}

// Create Azure Functions with monitoring
resource "azurerm_application_insights" "budgets" {
  name                = "budgets${random_string.suffix.result}"
  location            = azurerm_resource_group.budgets.location
  resource_group_name = azurerm_resource_group.budgets.name
  application_type    = "web"
}

resource "azurerm_app_service_plan" "budgets" {
  name                = "budgets-functions-plan"
  location            = azurerm_resource_group.budgets.location
  resource_group_name = azurerm_resource_group.budgets.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "budgets" {
  name                       = "budgets${random_string.suffix.result}"
  location                   = azurerm_resource_group.budgets.location
  resource_group_name        = azurerm_resource_group.budgets.name
  app_service_plan_id        = azurerm_app_service_plan.budgets.id
  storage_account_name       = azurerm_storage_account.budgets.name
  storage_account_access_key = azurerm_storage_account.budgets.primary_access_key
  version                    = "~3"
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY           = azurerm_application_insights.budgets.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME                 = "powershell"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.budgets.primary_connection_string
    HASH                                     = base64encode(filesha256("automationFunctions.zip"))
    WEBSITE_RUN_FROM_PACKAGE                 = "${azurerm_storage_blob.code.url}${data.azurerm_storage_account_sas.storage_sas.sas}"
  }
}

// Setup Azure Function managed identity as Contributor in subscription so it can run automations (stop VMs, delete resources)
data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "example" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_function_app.budgets.identity[0].principal_id
}
