param environmentName string = uniqueString(resourceGroup().id)

@description('The datacenter to use for the deployment.')
param location string = resourceGroup().location

param containerImage string


var kvName = '${environmentName}-kv'

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
}

module app 'app.bicep' = {
  name: '${deployment().name}--app'
  params: {
    IoTHubEventHubCompatibleConnectionString: kv.getSecret('IoTHubEventHubCompatibleConnectionString')
    IoTHubSharedAccessSignature: kv.getSecret('IoTHubSharedAccessSignature')
    containerImage: containerImage
    location: location
  }
}
