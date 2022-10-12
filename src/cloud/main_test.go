package main

import (
	"encoding/json"
	"testing"
)

type MockedDevice struct {
	DeviceId string
}

func (d MockedDevice) InvokeMethod(deviceCommand DeviceCommand) DeviceInvocationResult {
	return DeviceInvocationResult{
		StatusCode: 200,
		Result:     true,
	}
}

func TestAdd(t *testing.T) {

	mockedDevice := MockedDevice{
		DeviceId: "mockeddevice",
	}

	telemtryToTest := DeviceTelemetryData{
		FunctionalLocation: "Reception Area", //Reception Area, Pickup Area, Parking Lot
		CurrentTask:        "test",
		ControlType:        "Manual",
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
