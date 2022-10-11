package main

import "testing"

type MockedDevice struct {
	DeviceId string
}

func (d *MockedDevice) InvokeMethod(deviceCommand DeviceCommand) string {

	if deviceCommand.Payload["parkinglot"] == "p1" {
		return "positive"
	} else {
		return "negative"
	}
}

func TestAdd(t *testing.T) {
	deviceId := "hello"
	mockedDevice := MockedDevice{
		DeviceId: deviceId,
	}

	got := mockedDevice.InvokeMethod(DeviceCommand{
		MethodName:               "drive",
		ResponseTimeoutInSeconds: 200,
		Payload: map[string]string{
			"parkinglot": "p1",
		},
	})
	want := "positive"

	if got != want {
		t.Errorf("got %q, wanted %q", got, want)
	}
}
