import cv2
import os
import pyzbar.pyzbar as pyzbar
from paho.mqtt import client as mqtt_client
from datetime import datetime

location = "NONE"
camera = cv2.VideoCapture(0)

#camera.set(3,width)
#camera.set(4,height)

device_id = os.getenv("DEVICE_ID") + "-geofences"
broker_name = "localhost"
broker_port = 1883
topic = "functionallocation"


def connect_mqtt() -> mqtt_client:
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print("Failed to connect, return code %d\n", rc)

    client = mqtt_client.Client(device_id)
    client.on_connect = on_connect
    client.connect(broker_name, broker_port)
    return client

client = connect_mqtt()
client.loop_start()

def decodeCam(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    barcodes = pyzbar.decode(gray)
    print('reading...', end='\r')
    for barcode in barcodes:
        barcodeData = barcode.data.decode()
        barcodeType = barcode.type
        updateLocation(barcodeData)
    return image

def updateLocation(newLocation):
  global location
  if (location != newLocation):
    location = newLocation
    print("Location Change:{}".format(location))
    client.publish(topic, location)


def run():
    try:
      while True:
        # Read current frame
        ret, frame = camera.read()
        im=decodeCam(frame)
    except KeyboardInterrupt:
        client.loop_stop()
        print('interrupted!')
        

if __name__ == '__main__':
    run()