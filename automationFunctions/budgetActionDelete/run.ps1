using namespace System.Net

param($Request, $TriggerMetadata)

$ResourceGroup = $Request.Body.data.BudgetName

Write-Host "Removing resource locks in $ResourceGroup"
Get-AzResourceLock -ResourceGroupName $ResourceGroup | Remove-AzResourceLock -Force

Write-Host "Removing Resource Group"
$result = Get-AzResourceGroup -Name $ResourceGroup | Remove-AzResourceGroup -Force -AsJob 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })
