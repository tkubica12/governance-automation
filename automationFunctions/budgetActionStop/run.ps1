using namespace System.Net

param($Request, $TriggerMetadata)

$ResourceGroup = $Request.Body.data.BudgetName

Write-Host "Removing resource locks in $ResourceGroup"
Get-AzResourceLock -ResourceGroupName $ResourceGroup | Remove-AzResourceLock -Force

Write-Host "Stopping VMs in Resource Group $ResourceGroup"
$result = Get-AzResourceGroup -Name $ResourceGroup | Get-AzVM | Stop-AzVM -Force -AsJob

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $result
    })
