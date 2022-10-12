param environmentName string = 'env-${uniqueString(resourceGroup().id)}'

@description('The datacenter to use for the deployment.')
param location string = resourceGroup().location

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

output IoTHubEventHubCompatibleConnectionString string = iothub.outputs.IoTHubEventHubCompatibleConnectionString
output IoTHubSharedAccessSignature string = iothub.outputs.IoTHubSharedAccessSignature

