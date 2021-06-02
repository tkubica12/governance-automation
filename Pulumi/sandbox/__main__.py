"""An Azure RM Python Pulumi program"""

import pulumi
import pulumi_azure_native as azure_native
from pulumi_azure_native.insights.v20200202preview import Component
from pulumi import *
from pulumi import export

# Budgets inputs
sandboxes = [
  {
    "name": "research1",
    "ownerId": "7424fb4c-5e9f-45cd-9f7d-453d45655e75",  # tokubica
    "ownerEmail": "tomas.kubica@microsoft.com",
    "monthlyBudget": 100
  },
  {
    "name": 'research2',
    "ownerId": '7424fb4c-5e9f-45cd-9f7d-453d45655e75', # tokubica
    "ownerEmail": 'tomas.kubica@microsoft.com',
    "monthlyBudget": 80
  },
  {
    "name": 'research3',
    "ownerId": '7424fb4c-5e9f-45cd-9f7d-453d45655e75', # tokubica
    "ownerEmail": 'tomas.kubica@microsoft.com',
    "monthlyBudget": 5
  }
]

# Budgets Resource Group
resourceGroup = azure_native.resources.ResourceGroup('budgets',
    resource_group_name="budgets")

# Budgets Storage Account
budgetStorageAccount = azure_native.storage.StorageAccount("budgets",
    # account_name=random.RandomId("budgets", prefix="budgets", byte_length=8).hex,
    resource_group_name=resourceGroup.name,
    sku=azure_native.storage.SkuArgs(
        name=azure_native.storage.SkuName.STANDARD_LRS,
    ),
    kind=azure_native.storage.Kind.STORAGE_V2)

# Container in storage account
codeContainer = azure_native.storage.BlobContainer("code",
    account_name=budgetStorageAccount.name,
    container_name="code",
    resource_group_name=resourceGroup.name)

# Upload Azure Function source to storage
blob = azure_native.storage.Blob("automationFunctions.zip",
    blob_name="automationFunctions.zip",
    container_name=codeContainer.name,
    account_name=budgetStorageAccount.name,
    resource_group_name=resourceGroup.name,
    source=pulumi.FileAsset("automationFunctions.zip"))

# Get SAS
functionsSas = azure_native.storage.list_storage_account_sas(account_name=budgetStorageAccount.name,
    resource_group_name=resourceGroup.name,
    permissions="r",
    resource_types="o",
    services="b",
    shared_access_expiry_time="2031-01-01",
    opts=ResourceOptions(depends_on=[resourceGroup, codeContainer]))

# Complete blob URL with SAS
url = Output.concat(blob.url, "?", functionsSas.account_sas_token)

# Log Analytics workspace
workspace = azure_native.operationalinsights.Workspace("budgets",
    resource_group_name=resourceGroup.name,
    sku=azure_native.operationalinsights.WorkspaceSkuArgs(
        name="PerGB2018",
    )
)

# Application Insights
appInsights = Component("budgets",
    resource_group_name=resourceGroup.name,
    application_type="web",
    flow_type="Bluefield",
    kind="web",
    request_source="rest",
    workspace_resource_id=workspace.id)

# Azure Function plan
functionsPlan = azure_native.web.AppServicePlan("functionsPlan",
    resource_group_name=resourceGroup.name,
    # kind="app",
    sku=azure_native.web.SkuDescriptionArgs(
        # capacity=1,
        # family="P",
        name="Y1",
        # size="P1",
        tier="Dynamic",
    ))

# Azure Function storage
functionStorageAccount = azure_native.storage.StorageAccount("function",
    resource_group_name=resourceGroup.name,
    sku=azure_native.storage.SkuArgs(
        name=azure_native.storage.SkuName.STANDARD_LRS,
    ),
    kind=azure_native.storage.Kind.STORAGE_V2)

# Storage key and connection string
functionStorageKey = pulumi.Output.all(resourceGroup.name, functionStorageAccount.name) \
    .apply(lambda args: azure_native.storage.list_storage_account_keys(
        resource_group_name=args[0],
        account_name=args[1]
    )).apply(lambda accountKeys: accountKeys.keys[0].value)
functionStorageString = Output.concat("DefaultEndpointsProtocol=https;AccountName=", functionStorageAccount.name, ";EndpointSuffix=core.windows.net;AccountKey=", functionStorageKey)

# Azure Function
function = azure_native.web.WebApp("budgets",
    resource_group_name=resourceGroup.name,
    server_farm_id=functionsPlan.id,
    kind="functionapp",
    identity=azure_native.web.ManagedServiceIdentityArgs(
        type="SystemAssigned",
    ),
    site_config=azure_native.web.SiteConfigArgs(
        app_settings=[
            azure_native.web.NameValuePairArgs(name="APPINSIGHTS_INSTRUMENTATIONKEY", value=appInsights.instrumentation_key),
            azure_native.web.NameValuePairArgs(name="FUNCTIONS_WORKER_RUNTIME", value="powershell"),
            azure_native.web.NameValuePairArgs(name="WEBSITE_CONTENTAZUREFILECONNECTIONSTRING", value=functionStorageString),
            azure_native.web.NameValuePairArgs(name="WEBSITE_RUN_FROM_PACKAGE", value=url)],
    ))

functionHostKey = Output.concat(azure_native.web.list_web_app_host_keys(function.name, resourceGroup.name).master_key)
budgetActionDeleteUrl = Output.concat("https://", function.name, ".azurewebsites.net/api/budgetActionDelete?code=", functionHostKey)
budgetActionStopUrl = Output.concat("https://", function.name, ".azurewebsites.net/api/budgetActionStop?code=", functionHostKey)

# Action Groups
actionStop = azure_native.insights.ActionGroup("budgetReactionStop",
    resource_group_name=resourceGroup.name,
    location="global",
    action_group_name="budgetReactionStop",
    enabled=True,
    group_short_name="budgetStop",
    azure_function_receivers=[azure_native.insights.AzureFunctionReceiverArgs(
        function_app_resource_id=function.id,
        function_name="budgetActionStop",
        http_trigger_url=budgetActionStopUrl,
        name="budgetReactionStop",
        use_common_alert_schema=False,
    )],
)

actionDelete = azure_native.insights.ActionGroup("budgetReactionDelete",
    resource_group_name=resourceGroup.name,
    location="global",
    action_group_name="budgetReactionDelete",
    enabled=True,
    group_short_name="budgetDelete",
    azure_function_receivers=[azure_native.insights.AzureFunctionReceiverArgs(
        function_app_resource_id=function.id,
        function_name="budgetActionDelete",
        http_trigger_url=budgetActionDeleteUrl,
        name="budgetReactionStop",
        use_common_alert_schema=False,
    )],
)

# Sandboxes

## Sandbox resource groups
sandboxResourceGroups = []
for sandbox in sandboxes:
    sandboxResourceGroups.append(azure_native.resources.ResourceGroup(sandbox['name'], resource_group_name=sandbox['name']))

## RBAC
for i, sandbox in enumerate(sandboxes):
    azure_native.authorization.RoleAssignment(sandbox['name'],
        principal_id=sandbox['ownerId'],
        principal_type="User",
        role_definition_id="/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635",
        scope=sandboxResourceGroups[i].id)

## Budget
for i, sandbox in enumerate(sandboxes):
    azure_native.consumption.Budget(sandbox['name'],
        amount=sandbox['monthlyBudget'],
        budget_name=sandbox['name'],
        category="Cost",
        scope=sandboxResourceGroups[i].id,
        time_grain="Monthly",
        time_period=azure_native.consumption.BudgetTimePeriodArgs(
            end_date="2031-12-01T00:00:00Z",
            start_date="2021-06-01T00:00:00Z",
        ),
        notifications={
            "basicNotification": azure_native.consumption.NotificationArgs(
                contact_emails=[
                    sandbox['ownerEmail']
                ],
                enabled=True,
                operator="GreaterThan",
                threshold=80,
                threshold_type="Actual",
            ),
            "stop": azure_native.consumption.NotificationArgs(
                contact_emails=[
                    sandbox['ownerEmail']
                ],
                contact_groups=[actionStop.id],
                enabled=True,
                operator="GreaterThan",
                threshold=100,
                threshold_type="Actual",
            ),
            "delete": azure_native.consumption.NotificationArgs(
                contact_emails=[
                    sandbox['ownerEmail']
                ],
                contact_groups=[actionDelete.id],
                enabled=True,
                operator="GreaterThan",
                threshold=120,
                threshold_type="Actual",
            ),
        }
        )
    
