param location string

param iotHubName string

@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'

@description('The number of IoT Hub units.')
param skuUnits int = 1

@description('Partitions used for the event stream.')
param d2cPartitions int = 4

resource IoTHub 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: d2cPartitions
      }
    }
    routing: {
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
  }
}

#disable-next-line outputs-should-not-contain-secrets
output IoTHubEventHubCompatibleConnectionString string = 'Endpoint=${IoTHub.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${IoTHub.listkeys().value[0].primaryKey};EntityPath=${IoTHub.properties.eventHubEndpoints.events.path}'

#disable-next-line outputs-should-not-contain-secrets
output IoTHubSharedAccessSignature string = 'SharedAccessSignature sr=${IoTHub.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${IoTHub.listkeys().value[0].primaryKey}'
