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

type DeviceTelemetry struct {
	DeviceId string
	Payload  string
}

type DeviceCommand struct {
	MethodName               string
	ResponseTimeoutInSeconds int
	Payload                  map[string]string
}

func main() {
	s := daprd.NewService("9005")

	if err := s.AddBindingInvocationHandler("iothub", telemetryHandler); err != nil {
		log.Fatalf("Unable to subcribe to telemetry: %v", err)
	}

	if err := s.Start(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Unable to start server: %v", err)
	}
}

func invokeMethodOnDevice(deviceId string, deviceCommand DeviceCommand) {
	client, err := dapr.NewClient()

	if err != nil {
		log.Fatalf("Unable to create dapr client: %v", err)
	}

	keys, err := client.GetSecret(context.Background(), "secrets", "keys")

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

func telemetryHandler(ctx context.Context, in *common.BindingEvent) (out []byte, err error) {
	log.Printf("binding - Data:%s, Meta:%v", in.Data, in.Metadata)

	var deviceTelemetry DeviceTelemetry

	if err := json.Unmarshal(in.Data, &deviceTelemetry); err != nil {
		log.Fatalf("Unable to parse device telemetry event: %v", err)
	}

	//call device to do something

	//Decission logic tbd

	invokeMethodOnDevice(deviceTelemetry.DeviceId, DeviceCommand{
		MethodName:               "drive",
		ResponseTimeoutInSeconds: 200,
		Payload: map[string]string{
			"parkinglot": "p1",
		},
	})

	//check...

	return nil, nil
}
