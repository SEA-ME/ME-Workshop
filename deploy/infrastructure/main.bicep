param environmentName string = uniqueString(resourceGroup().id)

@description('The datacenter to use for the deployment.')
param location string = resourceGroup().location

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param identityObjectId string

// Storage
module storage 'storage.bicep' = {
  name: '${deployment().name}--storage'
  params: {
    storageAccountName: '${toLower(environmentName)}st'
    storageContainerName: 'checkpoints'
    location: location
  }
}

// IoT Hub
module iothub 'iothub.bicep' = {
  name: '${deployment().name}--iothub'
  params: {
    iotHubName: '${environmentName}-iot'
    location: location
  }
}

// Container Registry
module acr 'containerregistry.bicep' = {
  name: '${deployment().name}--acr'
  params: {
    acrName: '${environmentName}cr'
    location: location
  }
}

// Container Apps Environment 
module environment 'environment.bicep' = {
  name: '${deployment().name}--environment'
  params: {
    environmentName: '${environmentName}-env'
    location: location
    appInsightsName: '${environmentName}-ai'
    logAnalyticsWorkspaceName: '${environmentName}-la'
  }
}

// Key Vault
module keyvault 'keyvault.bicep' = {
  name: '${deployment().name}--keyvault'
  params: {
    keyVaultName: '${environmentName}-kv'
    objectId: identityObjectId
    IoTHubEventHubCompatibleConnectionString: iothub.outputs.IoTHubEventHubCompatibleConnectionString
    IoTHubSharedAccessSignature: iothub.outputs.IoTHubSharedAccessSignature
    location: location
  }
}
