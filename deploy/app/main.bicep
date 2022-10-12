param location string

param containerAppName string = '${environmentName}-app'
param containerImage string

param environmentName string = uniqueString(resourceGroup().id)

var acaEnvironmentName = '${environmentName}-env'
var registryName = '${environmentName}cr'
var storageAccountName = '${toLower(environmentName)}st'
var kvName = '${environmentName}-kv'
var iotHubName = '${environmentName}-iot'

var iothub_twinurl = 'https://${iotHubName}.azure-devices.net/twins/'

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
}

resource acaenvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: acaEnvironmentName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${environmentName}cr-id'
  location: location
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: acaenvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [
        {
          name: 'IoTHubEventHubCompatibleConnectionString'
          value: kv.getSecret('IoTHubEventHubCompatibleConnectionString')
        }
        {
          name: 'IoTHubSharedAccessSignature'
          value: kv.getSecret('IoTHubSharedAccessSignature')
        }
      ]
      registries: [
        {
          server: '${registryName}.azurecr.io'
          username: ''
          passwordSecretRef: ''
          identity: uami.id
        }
      ]
      dapr: {
        enabled: true
        appPort: 8080
        appId: containerAppName
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: containerAppName
          env: [
            {
              name: 'IoTHubSharedAccessSignature'
              secretRef: 'IoTHubSharedAccessSignature'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'myqueuerule'
            azureQueue: {
              queueName: 'events'
              queueLength: 100
              auth: [
                {
                  secretRef: 'IoTHubEventHubCompatibleConnectionString'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
}

resource iothubInvokeDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: '${acaenvironment.name}/iothub_invoke'
  dependsOn: [
    acaenvironment
  ]
  properties: {
    componentType: 'bindings.http'
    version: 'v1'
    metadata: [
      {
        name: 'url'
        value: iothub_twinurl
      }
    ]
    scopes: [
      containerApp.name
    ]
  }
}

resource iothubDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: '${acaenvironment.name}/iothub'
  dependsOn: [
    acaenvironment
  ]
  properties: {
    componentType: 'bindings.azure.eventhubs'
    version: 'v1'
    secrets: [
      {
        name: 'connectionString'
        value: kv.getSecret('IoTHubEventHubCompatibleConnectionString')
      }
      {
        name: 'storageAccountKey'
        value: storageAccount.listAccountSas().accountSasToken
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'connectionString'
      }
      {
        name: 'consumerGroup'
        value: '$Default'
      }
      {
        name: 'storageAccountName'
        value: storageAccountName
      }
      {
        name: 'storageAccountKey'
        secretRef: 'storageAccountKey'
      }
      {
        name: 'storageContainerName'
        value: 'checkpoints'
      }
    ]
    scopes: [
      containerApp.name
    ]
  }
}
