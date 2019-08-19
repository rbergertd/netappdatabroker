Login-AzureRmAccount
Select-AzureRmSubscription -subscriptionName <SB_NAME>
New-AzureRmResourceGroup -Name <RG_NAME> -Location <LOCATION>
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name <SUBNET_NAME> -AddressPrefix <SUBNET_CIDR>
New-AzureRmVirtualNetwork -Name <VNET_NAME> -ResourceGroupName <RG_NAME> -Location <LOCATION> -AddressPrefix <VNET_CIDR_PREFIX> -Subnet $subnet
New-AzureRmResourceGroupDeployment -Name <DEPLOYMENT_NAME> -ResourceGroupName <RG_NAME> -TemplateUri https://cf.cloudsync.netapp.com/5d4834ff614c3c000ad0d4f8 -StorageAccountType 'Standard_GRS' -subnetName <SUBNET_NAME> -adminPublicKey <KEY> -virtualMachineName <VM_NAME> -virtualNetworkName <VNET_NAME> -storageAccountName <SA_NAME>