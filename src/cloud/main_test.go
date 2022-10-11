package main

import (
	"encoding/json"
	"testing"
)

type MockedDevice struct {
	DeviceId string

	ReceivedDeviceCommand DeviceCommand

	ReturnValue string
}

func (d MockedDevice) InvokeMethod(deviceCommand DeviceCommand) DeviceInvocationResult {
	return DeviceInvocationResult{
		StatusCode: 200,
		Result:     true,
	}
}

func TestAdd(t *testing.T) {

	// Arrange
	deviceId := "hello"
	mockedDevice := MockedDevice{
		DeviceId:    deviceId,
		ReturnValue: "positive",
	}

	telemtryToTest := DeviceTelemetryData{
		FunctionalLocation: "test",
		ReturnArea:         "test",
		CurrentTask:        "test",
		ControlType:        "test",
	}
	data, _ := json.Marshal(telemtryToTest)
	want := true
	// Act
	result := routeCommands(mockedDevice, data)

	// Assert
	got := result

	if got == want {
	} else {
		t.Error()
	}
}
