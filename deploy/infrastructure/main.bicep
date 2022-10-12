param environmentName string = 'env-${uniqueString(resourceGroup().id)}'

@description('The datacenter to use for the deployment.')
param location string = resourceGroup().location

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param identityObjectId string

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Define the project name or prefix for all objects.')
@minLength(1)
@maxLength(11)
param projectName string = 'carsharing'

var storageAccountName = '${toLower(projectName)}${uniqueString(resourceGroup().id)}'
var storageContainerName = 'checkpoints'

var iotHubName = '${projectName}Hub${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the key vault.')
param keyVaultName string = '${projectName}KV'

// Storage
module storage 'storage.bicep' = {
  name: '${deployment().name}--storage'
  params: {
    storageAccountName: storageAccountName
    storageContainerName: storageContainerName
    location: location
  }
}

// IoT Hub
module iothub 'iothub.bicep' = {
  name: '${deployment().name}--iothub'
  params: {
    iotHubName: iotHubName
    location: location
  }
}

// Container Registry
module acr 'containerregistry.bicep' = {
  name: '${deployment().name}--acr'
  params: {
    acrName: acrName
    location: location
  }
}

// Container Apps Environment 
module environment 'environment.bicep' = {
  name: '${deployment().name}--environment'
  params: {
    environmentName: environmentName
    location: location
    appInsightsName: '${environmentName}-ai'
    logAnalyticsWorkspaceName: '${environmentName}-la'
  }
}

// Key Vault
module keyvault 'keyvault.bicep' = {
  name: '${deployment().name}--keyvault'
  params: {
    keyVaultName: keyVaultName
    objectId: identityObjectId
    IoTHubEventHubCompatibleConnectionString: iothub.outputs.IoTHubEventHubCompatibleConnectionString
    IoTHubSharedAccessSignature: iothub.outputs.IoTHubSharedAccessSignature
    location: location
  }
}
