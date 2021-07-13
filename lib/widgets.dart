import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:oximeter_app/main.dart';

class DevicesScan extends StatefulWidget {
  DevicesScan({Key? key}) : super(key: key);

  @override
  _DevicesScan createState() => _DevicesScan();
}

class _DevicesScan extends State<DevicesScan> {
  bool _active = false;
  List<BluetoothDevice> _connectedDevice = [];
  late StreamSubscription deviceStateSub;

  Future<void> connectDevice(BluetoothDevice device) async {
    print("connect");
    print(device.name);
      // await device.connect(timeout: Duration(seconds: 3));
      await device.connect(autoConnect: false, timeout: Duration(seconds: 3))
          .timeout(Duration(seconds: 3), onTimeout: (){
            print("Cannot connect to device!");
          }).then((value) {
            print("connected!");
          });

    deviceStateSub = device.state.listen((deviceState) {
      if (deviceState == BluetoothDeviceState.connected) {
        print("-----------Device Connected---------");
        // discoverServices(); // Function to request Services & find required service & char
      }
      if (deviceState == BluetoothDeviceState.disconnected) {
        // disconnect();  // function to handle disconnect event
        // myDevice = null;
        disconnectDevice(device);
        print("-----------Device Disconnected---------");
      }
    });

    setState(() {
      _active = true;
      _connectedDevice.add(device);
    });
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    print("disconnect");
    print(device.name);
    await device.disconnect();
    print("disconnected!");
    setState(() {
      _active = false;
      _connectedDevice.remove(device);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Device scan result"),
        StreamBuilder<List<ScanResult>>(
            stream: flutterBlue.scanResults,
            initialData: [],
            builder: (context, snapshot) {
              VoidCallback onPressed;
              onPressed = () => {print("Connect")};
              return Column(
                  children: snapshot.data!
                      .where((device) =>
                          device.device.type == BluetoothDeviceType.le &&
                          !_connectedDevice.contains(device.device))
                      .map((e) => Column(
                            children: [
                              Text("Device Name : " + e.device.name),
                              RaisedButton(
                                  onPressed: () => connectDevice(e.device),
                                  child: Text("Connect")),
                              // RaisedButton(onPressed: ()=>disconnectDevice(e),child: Text("Disconnect"))
                            ],
                          ))
                      .toList());
            }),
        Text("Connected Device"),
        StreamBuilder<List<BluetoothDevice>>(
            stream: flutterBlue.connectedDevices.asStream(),
            initialData: [],
            builder: (context, snapshot) {
              VoidCallback onPressed;
              onPressed = () => {print("Connect")};
              return Column(
                  children: snapshot.data!
                      // .where((device) => device.state == BluetoothDeviceState.connected)
                      .map((e) => Column(
                            children: [
                              Text("Device Name : " + e.name),
                              // RaisedButton(onPressed: ()=>connectDevice(e),child: Text("Connect")),
                              RaisedButton(
                                  onPressed: () => disconnectDevice(e),
                                  child: Text("Disconnect"))
                            ],
                          ))
                      .toList());
            })
      ],
    );
  }
}
