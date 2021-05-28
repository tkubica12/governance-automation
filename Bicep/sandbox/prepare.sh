# Create Resource Group
az group create -n budgets -l westeurope

# Create Storage Account
az storage account create -n tomasbudgets1645 -g budgets
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -n tomasbudgets1645 -g budgets --query connectionString -o tsv)

# Create storage container
az storage container create -n code

# Upload functions source zip
az storage blob upload -c code -f automationFunctions.zip -n automationFunctions.zip
export packageUrl=$(az storage blob generate-sas --permissions r --full-uri -c code -n automationFunctions.zip --expiry 2031-05-28T12:03:42Z -o tsv)

# Deploy
az bicep build -f main.bicep
az deployment sub create --template-file main.json -l westeurope --parameters packageUrl=$packageUrl
