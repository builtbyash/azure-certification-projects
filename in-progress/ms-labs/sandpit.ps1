Connect-AzAccount

New-AzResourceGroup -Name "udemy" -Location "eastus" -Force

Remove-AzResourceGroup -Name "udemy" -Force

$vNetName = "prod-vnet"
$subNetName = "frontend-subnet"

New-AzResourceGroupDeployment -ResourceGroupName "udemy" -TemplateFile "vnet.bicep" -vnetName $vNetName -subnetName $subNetName `
    -addressPrefix "10.0.0.0/16" -subnetPrefix "10.0.1.0/24"

New-AzResourceGroupDeployment -ResourceGroupName "udemy" -TemplateFile "private-dns.bicep" -privateDnsZoneName "udemy.local" `
    -vnetId $vNetName

$securePassword = ConvertTo-SecureString "vsdvfd446453DD%$gggzsdg" -AsPlainText -Force
New-AzResourceGroupDeployment -ResourceGroupName "udemy" -TemplateFile "ubuntu-nginx-vm.bicep" -vmName "web-server-02" -vnetName $vNetName `
    -subnetName "frontend-vnet" -adminUsername "ash" -adminPassword $securePassword -addressPrefix "10.0.0.0/16" -subnetPrefix "10.0.1.0/24"

