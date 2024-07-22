<#
Lab 05 - Implement Intersite Connectivity

Source: https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_05-Implement_Intersite_Connectivity.html
#>

Connect-AzAccount

New-AzResourceGroup -Name "az104-rg5" -Location "eastus" -Force

<# 
Task 1: Create a virtual machine in a virtual network.
#>

$subnet = New-AzVirtualNetworkSubnetConfig -Name "Core" -AddressPrefix "10.0.0.0/24"
New-AzVirtualNetwork -Name "CoreServicesVnet" -ResourceGroupName "az104-rg5" -Location "eastus" -AddressPrefix "10.0.0.0/16" -Subnet $subnet

New-AzResourceGroupDeployment -ResourceGroupName "az104-rg5" -TemplateFile "05LabVMTemplate.json" -TemplateParameterFile "05LabCoreServicesVMParameters.json"

<#
Task 2: Create a virtual machine in a different virtual network.
#>

$subnet = New-AzVirtualNetworkSubnetConfig -Name "Manufacturing" -AddressPrefix "172.16.0.0/24"
New-AzVirtualNetwork -Name "ManufacturingVnet" -ResourceGroupName "az104-rg5" -Location "eastus" -AddressPrefix "172.16.0.0/16" -Subnet $subnet

New-AzResourceGroupDeployment -ResourceGroupName "az104-rg5" -TemplateFile "05LabVMTemplate.json" -TemplateParameterFile "05LabManufacturingVMParameters.json"

<#
Task 3: Use Network Watcher to test the connection between virtual machines
#>

$CoreServicesVM = Get-AzVM -ResourceGroupName "az104-rg5" -Name "CoreServicesVM" -Status
$ManufacturingVM = Get-AzVM -ResourceGroupName "az104-rg5" -Name "ManufacturingVM" -Status

$CoreServicesVMPowerState = $CoreServicesVM.Statuses | Where-Object { $_.Code -match 'PowerState/' } | Select-Object -ExpandProperty DisplayStatus
$ManufacturingVMPowerState = $ManufacturingVM.Statuses | Where-Object { $_.Code -match 'PowerState/' } | Select-Object -ExpandProperty DisplayStatus

if ($CoreServicesVMPowerState -eq 'VM running' -and $ManufacturingVMPowerState -eq 'VM running') {
    Write-Host "Both VMs are running."
} else {
    Write-Host "One or both VMs are not running."
}

New-AzNetworkWatcher -Name "NetworkWatcher_eastus" -ResourceGroupName "az104-rg5" -Location "eastus"

$networkWatcherName = "NetworkWatcher_eastus" 
$sourceVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name "CoreServicesVM"
$destinationVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name "ManufacturingVM"
$destinationPort = 3389  

Test-AzNetworkWatcherConnectivity -NetworkWatcherName $networkWatcherName -ResourceGroupName $resourceGroupName -SourceId $sourceVM.Id -DestinationId $destinationVM.Id -ProtocolConfiguration $protocolConfiguration -DestinationPort $destinationPort

<#
Task 4: Configure virtual network peerings between virtual networks
#>

$CoreServicesVnet = Get-AzVirtualNetwork -Name "CoreServicesVnet" -ResourceGroupName "az104-rg5"
$ManufacturingVnet = Get-AzVirtualNetwork -Name "ManufacturingVnet" -ResourceGroupName "az104-rg5"

Add-AzVirtualNetworkPeering -Name "CoreServicesToManufacturing" -VirtualNetwork $CoreServicesVnet -RemoteVirtualNetworkId $ManufacturingVnet.Id -AllowForwardedTraffic
Add-AzVirtualNetworkPeering -Name "ManufacturingToCoreServices" -VirtualNetwork $ManufacturingVnet -RemoteVirtualNetworkId $CoreServicesVnet.Id -AllowForwardedTraffic

<#
Task 5: Use Azure PowerShell to test the connection between virtual machines
#>

$script = "Test-NetConnection 10.0.0.4 -Port 3389" # IP of CoreServicesVM
Invoke-AzVMRunCommand -ResourceGroupName "az104-rg5" -Name "ManufacturingVM" -CommandId "RunPowerShellScript" -ScriptString $script

<#
Task 6: Create a custom route
#>

# Add perimeter subnet to CoreServicesVnet

$vnet = Get-AzVirtualNetwork -ResourceGroupName "az104-rg5" -Name "CoreServicesVnet"
Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "Perimeter" -AddressPrefix "10.0.1.0/24"
$vnet | Set-AzVirtualNetwork

# Create a route table

$routeTable = New-AzRouteTable -ResourceGroupName "az104-rg5" -Location "eastus" -Name "rt-CoreServices"
Add-AzRouteConfig -Name "PerimetertoCore"-AddressPrefix "10.0.0.0/16" -NextHopType "VirtualAppliance" -NextHopIpAddress "10.0.1.7" -RouteTable $routeTable
$routeTable | Set-AzRouteTable
$vnet | Set-AzVirtualNetwork

# Associate route table with core subnet

$coreSubnet = Get-AzVirtualNetworkSubnetConfig -Name "Core" -VirtualNetwork $vnet
$coreSubnet.RouteTable = $routeTable
$vnet | Set-AzVirtualNetwork