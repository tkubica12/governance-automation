# Cloud governance automation
This repo contains example desired state automation for Azure governance starting with Terraform

Current status os Terraform/subscriptions
- customRoles.tf contains definitions of custom roles
  - There is one role defined called limitedContributor
  - We get list of all visible subscription and make is assignable scope list
- managementGroups.tf contains hierarchy definition for management groups and associated subscriptions
  - companyPolicy is applied on Production Management Group
- individual files per subscription such as eshopSubscription.tf and b2bSubscription.tf 
  - Each subscription file use subscription resource - in my case this is using existing pre-created subscriptions so works as "rename", but can be also used to create subscriptions
  - locals list is used to setup roles and mapping to users and groups - all by IDs
  - RBAC assignment loop based on locals list
- policies.tf containes custom initiatives definitions