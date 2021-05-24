# Cloud governance automation
This repo contains example desired state automation for Azure governance starting with Terraform

# Subscriptions management including Management Groups, access control, policies and budgets
This scenario provides basic structure for Azure governance:
- Creates hierarchy of Management Groups
- Creates Azure Policy definitions and assign those on certain Management Group or Subscriptions
- Creates custom RBAC roles
- Assign RBAC access control rules and assign to certain Management Group or Subscriptions
- Deploy basic subscription resources - in our case simple cost budget


Current status of Terraform/subscriptions
- customRoles.tf contains definitions of custom roles
  - There is one role defined called limitedContributor
  - We get list of all visible subscription and make is assignable scope list
- managementGroups.tf contains hierarchy definition for management groups and associated subscriptions
  - companyPolicy is applied on Production Management Group
- individual files per subscription such as eshopSubscription.tf and b2bSubscription.tf 
  - Each subscription file use subscription resource - in my case this is using existing pre-created subscriptions so works as "rename", but can be also used to create subscriptions
  - locals list is used to setup roles and mapping to users and groups - all by IDs
  - RBAC assignment loop based on locals list
- policies.tf contains custom initiatives definitions

# Sandbox environment
This scenario implements simple sandbox subscription solution:
- Each sandbox gets its own resource group with one Owner, who can provide access to other team members
- Each sandbox has budget created
- Budgets use Azure Functions to execute actions:
  - On 80% Owner is informed
  - On 100% all VMs in resource group are stopped
  - On 120% resource group is deleted and sandbox environment is destroyed

Current automation can be found in Terraform/sandbox
- inputs.tf contains map of sandboxes (in my example research1 etc.) with certain required parameters such as OwnerId (object ID of user account or AAD group), OwnerEmail (to be written to tag) and monthly budget amount
- supportInfra.tf deploy automation infrastructure to react on budget overspend. This contains storage account (used to store Azure Functions deployment code), Azure Functions with PowerShell and Action Groups
- main.tf contains logic to loop throw inputs and create resource groups, access control and budgets
- Azure Functions logic is stored in /automationFunctions to be reused regardless of type of Infra as Code tool(eg. Bicep version). Logic is written as simple PowerShell Azure commands, but can be reimplemented using Python or any other option. Note that for simplicity budget name = resource group name.