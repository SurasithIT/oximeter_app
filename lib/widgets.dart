import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:oximeter_app/main.dart';
import 'package:oximeter_app/src/services/BluetoothHelperService.dart';

// class DevicesScan extends StatefulWidget {
//   DevicesScan({Key? key}) : super(key: key);
//
//   @override
//   _DevicesScan createState() => _DevicesScan();
// }

class DevicesScan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Last connected"),
        RaisedButton(onPressed: ()=> bluetoothHelperService.connectLastedDevice(),child: Text("Connecttt"),),
        Text("Device scan result"),
        StreamBuilder<List<ScanResult>>(
            stream: bluetoothHelperService.flutterBlue.scanResults,
            initialData: [],
            builder: (context, snapshot) {
              VoidCallback onPressed;
              onPressed = () => {print("Connect")};
              return Column(
                  children: snapshot.data!
                      // .where((device) =>
                      //     device.device.type == BluetoothDeviceType.le &&
                      //     !BluetoothHelperService().connectedDevice.contains(device.device))
                      .map((e) => Column(
                            children: [
                              Text("Device Name : " + e.device.name),
                              RaisedButton(
                                  onPressed: () => bluetoothHelperService.connectDevice(e.device),
                                  child: Text("Connect")),
                              // RaisedButton(onPressed: ()=>disconnectDevice(e),child: Text("Disconnect"))
                            ],
                          ))
                      .toList());
            }),

        Text("all Connected Device from flutter blue"),
        StreamBuilder<List<BluetoothDevice>>(
          stream: bluetoothHelperService.flutterBlue.connectedDevices.asStream(),
          // stream: BluetoothHelperService().connectedDevices,
            initialData: [],
            builder: (context, snapshot) {
              VoidCallback onPressed;
              onPressed = () => {print("Connect")};
              return Column(
                  children: snapshot.data!
                      .where((device) => device.state == BluetoothDeviceState.connected)
                      .map((e) => Column(
                            children: [
                              Text("Device Name : " + e.name),
                              // RaisedButton(onPressed: ()=>connectDevice(e),child: Text("Connect")),
                              RaisedButton(
                                  onPressed: () => bluetoothHelperService.disconnectDevice(e),
                                  child: Text("Disconnect")),
                              // Text("SpO2 ${bluetoothHelperService.spo2}, PulseRate ${bluetoothHelperService.pulseRate}, PI ${bluetoothHelperService.pi}")
                            ],
                          ))
                      .toList());
            })
      ],
    );
  }
}


class ConnectedDevice extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("ConnectedDevice from bluetooth helper service"),
      StreamBuilder<List<BluetoothDevice>>(
        // stream: BluetoothHelperService().flutterBlue.connectedDevices.asStream(),
          stream: bluetoothHelperService.connectedDevices$,
          initialData: [],
          builder: (context, snapshot) {
            return Column(
                children: snapshot.data!
                    .map((e) => Column(
                  children: [
                    Text("Device Name : " + e.name),
                    // RaisedButton(onPressed: ()=>connectDevice(e),child: Text("Connect")),
                    RaisedButton(
                        onPressed: () => bluetoothHelperService.disconnectDevice(e),
                        child: Text("Disconnect")),
                    // Text("SpO2 ${bluetoothHelperService.spo2}, PulseRate ${bluetoothHelperService.pulseRate}, PI ${bluetoothHelperService.pi}")
                  ],
                ))
                    .toList());
          }),
    ],);
  }
}

class OximeterDataWidget extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("OximeterData"),
      StreamBuilder<Map<String, dynamic>>(
          stream: bluetoothHelperService.oximeterData$,
          initialData: {
                          'spO2' : 0,
                          'pulseRate' : 0,
                          'pi' : 0.0
                        },
          builder: (context, snapshot) {
            VoidCallback onPressed;
            onPressed = () => {print("Connect")};
            return Text("SpO2 ${snapshot.data?["spO2"]}, PulseRate ${snapshot.data?["pulseRate"]}, PI ${snapshot.data?["pi"]}");
          }),
    ],);
  }
}