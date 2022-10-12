The solution consists of two modules

- Geofences module updates the cloud with "functional locations". Functional locations are relevant to business operations and include "Parking Lot", "Reception Area" and "Pickup Area". The Geofences module uses the RaspberryPi camera to read QR codes that contain the functional location.
- CloudConnector module uses Azure IoT to send and receive messages to the cloud. It will send the D2C message to indicate the new functional location, The Geofences module listens to updates on the internal MQTT Broker on the /functionallocation topic to determine if there is a new message. The module accepts a "drive" command with a new functional location target.

To run the solution, set up the following environment variables:

``` bash
IOTHUB_DEVICE_CONNECTION_STRING="<Your IoT Device Connection String>"
DEVICE_ID="<Your IoT Device ID>"
```

Currently all interprocess communication is done using MQTT. The geofences module leverages the internalcommunication module to send and receive messages from other modules working on the vehicle.

The sample folder contains the individual "building blocks" used to create the geofences and cloud connector python modules.

It is recommended to set up a virtual python environment for this project, and import the references described in requirements.txt.

