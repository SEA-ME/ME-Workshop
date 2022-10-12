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

type DeviceInvocationResult struct {
	StatusCode int
	Result     bool
	Data       string
}

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
	Payload                  map[string]string
}

type Device interface {
	InvokeMethod(deviceCommand DeviceCommand) DeviceInvocationResult
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

func (d IoTHubDevice) InvokeMethod(deviceCommand DeviceCommand) DeviceInvocationResult {
	invocationResult := DeviceInvocationResult{
		StatusCode: 500,
		Result:     false,
	}

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
				Name:      "iothub-invoke",
				Operation: "post",
				Metadata: map[string]string{
					"path":          fmt.Sprintf("%v/methods?api-version=2021-04-12", "device1"),
					"Content-Type":  "application/json; charset=utf-8",
					"Authorization": auth,
				},
				Data: data,
			}
			if out, err := client.InvokeBinding(context.Background(), req); err != nil {
				log.Fatalf("unable to call IoTHub: %v", err)
			} else {
				if err := json.Unmarshal(out.Data, &invocationResult); err == nil {
					invocationResult.StatusCode = 200
					invocationResult.Result = true
				}
			}
			return invocationResult
		}
	} else {
		log.Fatalf("Secrets do not contain reference for SAS authorization to IoT Hub.")
	}
	return invocationResult
}

func routeCommands(deviceToCommand Device, data []byte) bool {
	//Currently not used... implement business logic to use the data
	var deviceTelemetryData DeviceTelemetryData
	if err := json.Unmarshal(data, &deviceTelemetryData); err != nil {
		log.Fatalf("Unable to parse device telemetry data from event: %v", err)
	}

	if deviceTelemetryData.FunctionalLocation == "Reception Area" {
		//Invoke remote hub

		//TODO: Add logic to decide which parking lot to select as location

		log.Println("Vehicle arrived and reception area. Sending it to parking")
		result := deviceToCommand.InvokeMethod(DeviceCommand{
			MethodName:               "drive",
			ResponseTimeoutInSeconds: 200,
			Payload: map[string]string{
				"location": "parking2",
			},
		})
		return result.Result
	}

	return false
}

func telemetryHandler(ctx context.Context, in *common.BindingEvent) (out []byte, err error) {
	log.Printf("binding - Data:%s, Meta:%v", in.Data, in.Metadata)

	if deviceId, hasDeviceId := in.Metadata["Iothub-Connection-Device-Id"]; hasDeviceId {

		device := IoTHubDevice{
			DeviceId: deviceId,
		}

		routeCommands(device, in.Data)

	} else {
		log.Fatal("Unable to read the deviceId from event.")
	}

	return nil, nil
}
