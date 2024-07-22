<#
Lab 03 - Manage Azure resources by using Azure Resource Manager Templates

Source: https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_03b-Manage_Azure_Resources_by_Using_ARM_Templates.html
#>

Connect-AzAccount

New-AzResourceGroup -Name "az104-rg3" -Location "eastus" -Force

<#
Task 1: Create an Azure Resource Manager template
Task 2: Edit an Azure Resource Manager template and then redeploy the template
Task 3: Deploy a template with PowerShell
#>

New-AzResourceGroupDeployment -ResourceGroupName "az104-rg3" -TemplateFile "03LabDiskTemplate.json" -TemplateParameterFile "03LabDiskParameters.json"

Get-AzDisk

<#
Task 5: Deploy a resource by using Azure Bicep
#>

New-AzResourceGroupDeployment -ResourceGroupName "az104-rg3" -TemplateFile "03LabDisk.bicep"