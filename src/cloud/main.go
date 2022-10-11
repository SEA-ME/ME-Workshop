package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/dapr/go-sdk/service/common"
	daprd "github.com/dapr/go-sdk/service/http"

	dapr "github.com/dapr/go-sdk/client"
)

type DeviceTelemetryData struct {
	FunctionalLocation string
	ReturnArea         string
	CurrentTask        string
	ControlType        string
}

type DeviceCommand struct {
	DeviceId                 string
	MethodName               string
	ResponseTimeoutInSeconds int
	Payload                  []byte
}

type Device interface {
	InvokeMethod(deviceCommand DeviceCommand)
}

type IoTHubDevice struct {
	DeviceId string
}

const SERVICE_PORT int = 8080

func main() {
	s := daprd.NewService(fmt.Sprintf(":%d", SERVICE_PORT))

	if err := s.AddBindingInvocationHandler("iothub", telemetryHandler); err != nil {
		log.Fatalf("Unable to subcribe to telemetry: %v", err)
	}

	if err := s.Start(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Unable to start server: %v", err)
	}
}

func (d IoTHubDevice) InvokeMethod(deviceCommand DeviceCommand) {
	client, err := dapr.NewClient()

	if err != nil {
		log.Fatalf("Unable to create dapr client: %v", err)
	}

	keys, err := client.GetSecret(context.Background(), "secrets", "keys", nil)

	if err != nil {
		log.Fatalf("Unable to fetch iot hub invoke authorization info: %v", err)
	}

	if auth, hasKey := keys["iothub_sharedaccesskey"]; hasKey {

		if data, err := json.Marshal(deviceCommand); err != nil {
			log.Fatalf("Unable to parse device command: %v", deviceCommand)
		} else {
			req := &dapr.InvokeBindingRequest{
				Name:      "iothub_invoke",
				Operation: "post",
				Metadata: map[string]string{
					"path":          fmt.Sprintf("%v/methods?api-version=2021-04-12", "device1"),
					"Content-Type":  "application/json; charset=utf-8",
					"Authorization": auth,
				},
				Data: data,
			}
			client.InvokeBinding(context.Background(), req)
		}
	} else {
		log.Fatalf("Secrets do not contain reference for SAS authorization to IoT Hub.")
	}
}

func routeCommands(deviceToCommand Device, data []byte) {
	//Currently not used... implement business logic to use the data
	var deviceTelemetryData DeviceTelemetryData
	if err := json.Unmarshal(data, &deviceTelemetryData); err != nil {
		log.Fatalf("Unable to parse device telemetry data from event: %v", err)
	}

	//Invoke remote hub
	deviceToCommand.InvokeMethod(DeviceCommand{
		MethodName:               "drive",
		ResponseTimeoutInSeconds: 200,
		Payload:                  data,
	})
}

func telemetryHandler(ctx context.Context, in *common.BindingEvent) (out []byte, err error) {
	log.Printf("binding - Data:%s, Meta:%v", in.Data, in.Metadata)

	if deviceId, hasDeviceId := in.Metadata["Iothub-Connection-Device-Id"]; hasDeviceId {

		//call device to do something

		//Decission logic tbd

		device := IoTHubDevice{
			DeviceId: deviceId,
		}

		routeCommands(device, in.Data)

		//check...

	} else {
		log.Fatal("Unable to read the deviceId from event.")
	}

	return nil, nil
}
