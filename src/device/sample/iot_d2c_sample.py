import os
import asyncio
import json

from azure.iot.device.aio import IoTHubDeviceClient

import ssl



async def main():
    # Fetch the connection string from an environment variable
    conn_str = os.getenv("IOTHUB_DEVICE_CONNECTION_STRING")
    device_id = os.getenv("DEVICE_ID")

    # Create instance of the device client using the authentication provider
    device_client = IoTHubDeviceClient.create_from_connection_string(conn_str)

    # Connect the device client.
    await device_client.connect()
    # Send a single message
    print("Sending message...")

    msg = {
        "FunctionalLocation": "ReturnArea",
        "CurrentTask": "Wait",
        "ControlType": "Manual"
    }


    await device_client.send_message(json.dumps(msg))

    print("Message successfully sent:", msg)

    # finally, shut down the client
    await device_client.shutdown()


if __name__ == "__main__":
    asyncio.run(main())