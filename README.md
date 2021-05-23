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