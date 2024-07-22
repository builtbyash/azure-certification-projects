<#
Lab 04 - Implement Virtual Networking

Source: https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_04-Implement_Virtual_Networking.html
#>

Connect-AzAccount

New-AzResourceGroup -Name "az104-rg4" -Location "eastus" -Force

<#
Task 1: Create a virtual network with subnets using the portal.
Task 2: Create a virtual network and subnets using a template.
#>

New-AzResourceGroupDeployment -ResourceGroupName "az104-rg4" -TemplateFile "04LabVNetTemplate.json" -TemplateParameterFile "04LabVNetParameters.json"

<#
Task 3: Create and configure communication between an Application Security Group and a Network Security Group
#>

# Create the Network Security Group and associate it with the ASG subnet

New-AzApplicationSecurityGroup -ResourceGroupName "az104-rg4" -Location "eastus" -Name "asg-web"
New-AzNetworkSecurityGroup -ResourceGroupName "az104-rg4" -Location "eastus" -Name "myNSGSecure"

$nsg = Get-AzNetworkSecurityGroup -Name "myNSGSecure" -ResourceGroupName "az104-rg4"
$subnet.NetworkSecurityGroup = $nsg
$vnet = Get-AzVirtualNetwork -ResourceGroupName "az104-rg4" -Name "ManufacturingVnet"
$vnet = Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet.Name -AddressPrefix $subnet.AddressPrefix -NetworkSecurityGroup $nsg
Set-AzVirtualNetwork -VirtualNetwork $vnet

# Configure an inbound security rule to allow ASG traffic

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
    -Name "AllowASG-HTTP" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 100 `
    -SourceApplicationSecurityGroup $asg `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "80"

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
    -Name "AllowASG-HTTPS" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 200 `
    -SourceApplicationSecurityGroup $asg `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "443"

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
    -Name "DenyAnyCustom8080Outbound" `
    -Access "Deny" `
    -Protocol "*" `
    -Direction "Outbound" `
    -Priority 4096 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "Internet" `
    -DestinationPortRange "*"

# Apply the updated NSG configuration
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg


<#
Task 4: Configure public and private Azure DNS zones
#>

# Configure a public DNS zone

New-AzDnsZone -ResourceGroupName "az104-rg4" -Name "ash-contoso.com" -ZoneType "Public"

$recordSetParams = @{
    ResourceGroupName = "az104-rg4"
    ZoneName          = "ash-contoso.com"
    Name              = "www"
    RecordType        = "A"
    Ttl               = 3600
}

$aRecord = New-AzDnsRecordConfig -Ipv4Address "10.1.1.4"

$recordSetParams.DnsRecords = $aRecordd
New-AzDnsRecordSet @recordSetParams

# Configure a private DNS zone

New-AzPrivateDnsZone -ResourceGroupName "az104-rg4" -Name "private.ash-contoso.com"

$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName "az104-rg4" -Name "ManufacturingVnet"
New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName "az104-rg4" -ZoneName "private.ash-contoso.com" -Name "manufacturing-link" -VirtualNetworkId $virtualNetwork.Id

$privateARecord = New-AzPrivateDnsRecordConfig -Ipv4Address "10.1.1.4"
New-AzPrivateDnsRecordSet -Name "sensorvm" -RecordType "A" -ResourceGroupName "az104-rg4" -Ttl 3600 -ZoneName "private.ash-contoso.com" -PrivateDnsRecords $privateARecord