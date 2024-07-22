<#
Lab 06 - Implement Traffic Management

Source: https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_06-Implement_Network_Traffic_Management.md
#>

Connect-AzAccount

New-AzResourceGroup -Name "az104-rg6" -Location "eastus" -Force

<#
Task 1: Use a template to provision an infrastructure
#>

# Deployed within Azure Portal (custom template deployment)

<#
Task 2: Configure an Azure Load Balancer
#>

$resourceGroupName = "az104-rg6"
$lbName = "az104-lb"

$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "az104-lbpip" `
    -AllocationMethod "Static" -Sku "Standard" -Location "eastus" -Tier "Regional"

$frontendIp = New-AzLoadBalancerFrontendIpConfig -Name "az104-fe" -PublicIpAddress $publicIp

New-AzLoadBalancer -ResourceGroupName $resourceGroupName -Name $lbName -Location "eastus" `
    -FrontendIpConfiguration $frontendIp -Sku "Standard"

$vm1 = Get-AzVM -ResourceGroupName $resourceGroupName -Name "az104-06-vm0"
$vm2 = Get-AzVM -ResourceGroupName $resourceGroupName -Name "az104-06-vm1"

# Create backend pool
$backendPool = New-AzLoadBalancerBackendAddressPool -ResourceGroupName $resourceGroupName -Name "az104-be" -LoadBalancerName $lbName

# Add VMs to the backend pool using their NIC private IP addresses
# Corrected to use Add-AzLoadBalancerBackendAddressPoolConfig instead of Add-AzLoadBalancerBackendAddressPoolBackend
# and corrected the way to get the IP address and NIC name
$nic1 = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName | Where-Object { $_.VirtualMachine.Id -eq $vm1.Id }
$nic2 = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName | Where-Object { $_.VirtualMachine.Id -eq $vm2.Id }

# The original code incorrectly attempted to add backend IP configurations directly. 
# The corrected approach involves updating the load balancer with the backend address pool that includes the NICs.
$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $resourceGroupName
$lb | Add-AzLoadBalancerBackendAddressPoolConfig -Name "az104-be" -BackendIPConfigurations $nic1.IpConfigurations[0], $nic2.IpConfigurations[0]
$lb | Set-AzLoadBalancer