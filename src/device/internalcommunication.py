import os
import asyncio
import json
from paho.mqtt import client as mqtt_client

def noopSendMessage(iot_msg):
    print("Noop IoT Message " + str(iot_msg))

class InternalCommunicationOverMQTT:

    def __init__(self):

        self.broker_name = "localhost"
        self.broker_port = 1883
        self.topic = "functionallocation"
        self.sendMessage = noopSendMessage

        def on_connect(client, userdata, flags, rc):
            if rc == 0:
                print("Connected to MQTT Broker!")
            else:
                print("Failed to connect, return code %d\n", rc)

        self.client = mqtt_client.Client("cloud-connector")
        self.client.on_connect = on_connect
        self.client.connect(self.broker_name, self.broker_port)       
        self.client.subscribe(self.topic)
        self.client.on_message = self.on_message

    def on_message(self, client, userdata, message,tmp=None):
        print(f"Received `{message.payload.decode()}` from `{message.topic}` topic")

        # Send a single message
        
        iot_msg = {
            "FunctionalLocation": message.payload.decode(),
            "CurrentTask": "Wait",
            "ControlType": "Manual"
        }
        
        asyncio.run(self.sendMessage(iot_msg))
        
    def start(self):
        self.client.loop_start()

    def stop(self):
        self.client.loop_stop()


