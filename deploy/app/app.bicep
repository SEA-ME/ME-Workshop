param containerAppName string = '${environmentName}-app'
param containerImage string

param environmentName string = uniqueString(resourceGroup().id)

@secure()
param IoTHubEventHubCompatibleConnectionString string

@secure()
param IoTHubSharedAccessSignature string

param location string

var acaEnvironmentName = '${environmentName}-env'
var registryName = '${environmentName}cr'
var storageAccountName = '${toLower(environmentName)}st'
var iotHubName = '${environmentName}-iot'

var iothub_twinurl = 'https://${iotHubName}.azure-devices.net/twins/'


resource acaenvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: acaEnvironmentName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${environmentName}-id'
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
          name: 'connectionstring'
          value: IoTHubEventHubCompatibleConnectionString
        }
        {
          name: 'sas'
          value: IoTHubSharedAccessSignature
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
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'IoTHubSharedAccessSignature'
              secretRef: 'sas'
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
                  secretRef: 'connectionstring'
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
  name: '${acaenvironment.name}/iothub-invoke'
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
        name: 'connectionstring'
        value: IoTHubEventHubCompatibleConnectionString
      }
      {
        name: 'storageaccountkey'
        value: storageAccount.listKeys().keys[0].value
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'connectionstring'
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
        secretRef: 'storageaccountkey'
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
