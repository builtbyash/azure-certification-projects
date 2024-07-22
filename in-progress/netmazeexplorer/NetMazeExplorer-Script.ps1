<#
NetMaze Explorer (Implement and manage virtual networking)

Design a hybrid networking environment where on-premises networks connect securely to Azure resources using Azure's 
networking capabilities, ensuring secure data transition and effective resource access controls.

Source: https://github.com/madebygps/projects/blob/main/az-104/netmazeexplorer.md
#>

Connect-AzAccount

$UbuntuServerTemplate = "UbuntuServerTemplate.json"

# Cloud network - West USA
$CloudResourceGroup = "netmazeexplorer-cloud-rg"
$CloudVNetName = "cloud-vnet"
$CloudLocation = "westus2"
$CloudVNetAddressPrefix = "10.0.0.0/16"
$CloudWebSubnet = New-AzVirtualNetworkSubnetConfig -Name "cloud-web-subnet" -AddressPrefix "10.0.1.0/24"
$CloudDBSubnet = New-AzVirtualNetworkSubnetConfig -Name "cloud-db-subnet" -AddressPrefix "10.0.2.0/24"
$CloudGatewaySubnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix "10.0.255.0/27"
$CloudGateway = "cloud-vpn-gw"

# Cloud web server
$CloudWebServerParameters = "CloudWebServerParameters.json"

# Cloud database
$CloudDatabaseParameters = "CosmosDBParameters.json"
$CloudDatabaseTemplate = "CosmosDBTemplate.json"

# On-premises network - Southeast Australia
$OnPremisesResourceGroup = "netmazeexplorer-onpremises-rg"
$OnPremisesVNetName = "onpremises-vnet"
$OnPremisesLocation = "australiasoutheast"
$OnPremisesVNetAddressPrefix = "192.168.0.0/16"
$OnPremisesSubnet = New-AzVirtualNetworkSubnetConfig -Name "onpremises-subnet" -AddressPrefix "192.168.1.0/24"
$OnPremisesGatewaySubnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix "192.168.255.0/27"
$OnPremisesGateway = "onpremises-vpn-gw"

# On-premises server
$OnPremisesServerParameters = "OnPremisesServerParameters.json"


<#
Create resource groups for entire network infrastructure
#>

New-AzResourceGroup -Name $CloudResourceGroup -Location $CloudLocation -Force
New-AzResourceGroup -Name $OnPremisesResourceGroup -Location $OnPremisesLocation -Force

<# 
1.  Azure Virtual Network Setup
Provision an Azure Virtual Network (VNet) in your chosen region.
Create multiple subnets within this VNet to segregate resources effectively (e.g., WebApp Subnet, Database Subnet, Admin Subnet).
#>

New-AzVirtualNetwork -Name $CloudVNetName -ResourceGroupName $CloudResourceGroup -Location $CloudLocation -AddressPrefix $CloudVNetAddressPrefix -Subnet $CloudWebSubnet, $CloudDBSubnet, $CloudGatewaySubnet


<#
2.  On-Premises Network Simulation
For the sake of this project, use another VNet to simulate your on-premises environment. This can be in another Azure region or the same region based on preference.
#>

New-AzVirtualNetwork -Name $OnPremisesVNetName -ResourceGroupName $OnPremisesResourceGroup -Location $OnPremisesLocation -AddressPrefix $OnPremisesVNetAddressPrefix -Subnet $OnPremisesSubnet, $OnPremisesGatewaySubnet


<#
3.  Secure Connectivity
Implement Azure VPN Gateway to create a site-to-site VPN connection between your simulated on-premises environment (VNet) and your main Azure VNet.
Verify the connection and ensure resources from one VNet can communicate with another, effectively simulating a hybrid environment.

References: 
https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-create-site-to-site-rm-powershell

"The subnet must be named 'GatewaySubnet' in order for Azure to deploy the gateway resources. You can't specify a different subnet to deploy the gateway resources to."
#>

# Assign public IP addresses for Cloud and On-Premises

$CloudPublicIP = New-AzPublicIpAddress -Name "cloud-publicip" -ResourceGroupName $CloudResourceGroup -Location $CloudLocation -AllocationMethod Static -Sku Standard -DdosProtectionMode "Disabled"
$OnPremisesPublicIP = New-AzPublicIpAddress -Name "onpremises-publicip" -ResourceGroupName $OnPremisesResourceGroup -Location $OnPremisesLocation -AllocationMethod Static -Sku Standard -DdosProtectionMode "Disabled"

# Create Virtual Network Gateway on the Cloud VNet

$Subnet = Get-AzVirtualNetwork -Name $CloudVNetName -ResourceGroupName $CloudResourceGroup | Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet"
$CloudGatewayConfig = New-AzVirtualNetworkGatewayIpConfig -Name $CloudGateway -SubnetId $Subnet.Id -PublicIpAddressId $CloudPublicIP.Id
$CloudVNetGateway = New-AzVirtualNetworkGateway -Name $CloudGateway -ResourceGroupName $CloudResourceGroup -Location $CloudLocation -IpConfigurations $CloudGatewayConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1

# Create Local Network Gateway for On-Premises on the Cloud VNet

$OnPremisesLocalNetworkGateway = New-AzLocalNetworkGateway -Name "onpremises-local-gw" -ResourceGroupName $CloudResourceGroup -Location $CloudLocation -GatewayIpAddress $OnPremisesPublicIP.IpAddress -AddressPrefix $OnPremisesVNetAddressPrefix

# Create the VPN Connection

New-AzVirtualNetworkGatewayConnection -Name "cloud-onpremises-vpn" -ResourceGroupName $CloudResourceGroup -Location $CloudLocation -VirtualNetworkGateway1 $CloudVNetGateway -LocalNetworkGateway2 $OnPremisesLocalNetworkGateway -ConnectionType IPsec -RoutingWeight 10 -SharedKey "ttJ8dh144@oKgwYRq3W31&4xJLcxO@"
Set-AzVirtualNetworkGatewayConnection -Name "cloud-onpremises-vpn" -ResourceGroupName $CloudResourceGroup -ConnectionStatus "Connected"

try {
    $VPN = Get-AzVirtualNetworkGatewayConnection -Name "cloud-onpremises-vpn" -ResourceGroupName $CloudResourceGroup -ErrorAction Stop
    switch ($VPN.ConnectionStatus) {
        "Connected" {
            Write-Host "VPN connection is connected."
        }
        "Connecting" {
            Write-Host "VPN connection is currently connecting."
        }
        default {
            Write-Host "VPN connection is not connected. Reason: $($VPN.ConnectionStatus)"
        }
    }
}
catch {
    Write-Host "Failed to get VPN connection status. Error: $_"
}

<#
4.  Resource Deployment
Deploy test resources (like VMs) in each subnet of your main Azure VNet. For instance, deploy a web server VM in the WebApp Subnet, a database in the Database Subnet, etc.
#>

New-AzResourceGroupDeployment -ResourceGroupName $OnPremisesResourceGroup -TemplateFile $UbuntuServerTemplate -TemplateParameterFile $OnPremisesServerParameters
New-AzResourceGroupDeployment -ResourceGroupName $CloudResourceGroup -TemplateFile $UbuntuServerTemplate -TemplateParameterFile $CloudWebServerParameters
New-AzResourceGroupDeployment -ResourceGroupName $CloudResourceGroup -TemplateFile $CloudDatabaseTemplate -TemplateParameterFile $CloudDatabaseParameters