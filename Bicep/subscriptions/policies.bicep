targetScope = 'managementGroup'

resource companyPolicy 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: 'companyPolicy'
  properties: {
    policyType: 'Custom'
    displayName: 'Example company policy'
     policyDefinitions: [
       {
         policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
         policyDefinitionReferenceId: 'inherit-owner'
         parameters: {
           tagName: {
             value: 'owner'
           }
         }
       }
       {
         policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/726aca4c-86e9-4b04-b0c5-073027359532'
         policyDefinitionReferenceId: 'write-class-unknown'
         parameters: {
           tagName: {
             value: 'class'
           }
           tagValue: {
             value: 'unknown'
           }
         }
       }
     ]
  }
}

