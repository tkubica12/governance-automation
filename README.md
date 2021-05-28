# Cloud governance automation
This repo contains example desired state automation for Azure governance with Terraform and Bicep.

# Subscriptions management including Management Groups, access control, policies and budgets
This scenario provides basic structure for Azure governance:
- Creates hierarchy of Management Groups
- Creates Azure Policy definitions and assign those on certain Management Group or Subscriptions
- Creates custom RBAC roles
- Assign RBAC access control rules and assign to certain Management Group or Subscriptions
- Deploy basic subscription resources - in our case simple cost budget

Two version are provided - Terraform and Bicep (Pulumi in future).

## Terraform
Current status of Terraform/subscriptions
- **customRoles.tf** contains definitions of custom roles
  - There is one role defined called limitedContributor
  - We get list of all visible subscription and make is assignable scope list
- **managementGroups.tf** contains hierarchy definition for management groups and associated subscriptions
  - companyPolicy is applied on Production Management Group
- **subscriptions.tf** can be used to create (if subscription ID is not provided and billing scope is provided) or just create alias (my case)
- individual files per subscription such as **eshopSubscription.tf and b2bSubscription.tf **
  - locals list is used to setup roles and mapping to users and groups - all by IDs
  - RBAC assignment loop based on locals list
- **policies.tf** contains custom initiatives definitions

TBD - Terroform module to demonstrate resource deployment in subscription such as spoke VNET

## Bicep
Current status of Bicep/subscriptions
- **customRoles.bicep** is module to create custom roles. Bicep cannot list all available subscriptions so AssignableScope is provided as configured array. There is one example role limitedContributor - Contributor with no rights to modify route tables (just an example - you might want to change this to disallow modifications of VNETs and other resources)
- **managementGroups.bicep** contains hierarchy definition for management groups and associated subscriptions and companyPolicy is applied on Production Management Group
- **subscriptions.bicep** can be used to create (if subscription ID is not provided and billing scope is provided) or just create alias (my case). Note as currently scopes in main.bicep when deploying on subscription scope do not support dynamic values scenario with subscription creation as part of template would rather be split to two deployments (or subscription creation would be scripted).
- individual files per subscription such as **eshopSubscription.bicep and b2bSubscription.bicep**
  - locals list is used to setup roles and mapping to users and groups - all by IDs
  - RBAC assignment loop based on locals list
- **policies.bicep** contains custom initiatives definitions

TBD - Bicep module to demonstrate resource deployment in subscription such as spoke VNET

# Sandbox environment
This scenario implements simple sandbox subscription solution:
- Each sandbox gets its own resource group with one Owner, who can provide access to other team members
- Each sandbox has budget created
- Budgets use Azure Functions to execute actions:
  - On 80% Owner is informed
  - On 100% all VMs in resource group are stopped
  - On 120% resource group is deleted and sandbox environment is destroyed
- There is one drawback you should be aware of due to how budgets are implemented in Azure - start time of budget must not be in distant past (for monthly budget it must be first of current month) when budget is created. So if you create budget, 3 months later delete and re-run template, you need to modify start time. This does not have negative effect on budget itself.

## Terraform
Current automation can be found in Terraform/sandbox
- inputs.tf contains map of sandboxes (in my example research1 etc.) with certain required parameters such as OwnerId (object ID of user account or AAD group), OwnerEmail (to be written to tag) and monthly budget amount
- supportInfra.tf deploy automation infrastructure to react on budget overspend. This contains storage account (used to store Azure Functions deployment code), Azure Functions with PowerShell and Action Groups
- main.tf contains logic to loop throw inputs and create resource groups, access control and budgets
- Azure Functions logic is stored in /automationFunctions to be reused regardless of type of Infra as Code tool(eg. Bicep version). Logic is written as simple PowerShell Azure commands, but can be reimplemented using Python or any other option. Note that for simplicity budget name = resource group name.

## Bicep
Current automation can be found in Bicep/sandbox
- Bicep does not support imperative steps such as upload something to storage directly. I could have use deploymentScript feature, but that would add unnecessary complexity since all we need is to make Azure Functions code zip file available in storage. Use commands in **prepare.sh** to upload code to storage or reference different store (such as GitHub repo).
- **main.bicep** contains sandboxes var in which you define all your sandboxes. It deploys all components and modules. main.bicep is targeting subscription scope.
- **rbac.bicep** is separate module because it configures RBAC on per resource group basis so cannot be deployed from main.bicep directly - module with RG scope is called in a loop
- **infrastructure.bicep** contains resource group scoped deployment of basic infrastructure such as Azure Function and Action Groups
- **budgets.bicep** is called in a loop and configures budget and notification for each sandbox





Planning - the same examples in Pulumi.