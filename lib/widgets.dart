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

  late BluetoothDevice? connectingDevice;
  List<Guid> configServices = [
    Guid('cdeacb80-5235-4c07-8846-93a37ee6b86d'), // Jumper
    Guid('49535343-fe7d-4ae5-8fa9-9fafd205e455') // Berry
  ];
  late StreamSubscription streamDataSubscription;

  int spo2 = 0;
  int pulseRate = 0;
  double pi = 0;

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

    deviceStateSub = device.state.listen((deviceState) async {
      if (deviceState == BluetoothDeviceState.connected) {
        print("-----------Device Connected---------");
        connectingDevice = device;
        List<BluetoothService> services = await connectingDevice!.discoverServices();
        services.forEach((service) async {
          // do something with service
          print("connecting device list service");
          print("uuid : " + service.uuid.toString());
          print("char : " + service.characteristics.toString());

          // discover services
          _getService(services);

          // var characteristics = service.characteristics;
          // for(BluetoothCharacteristic c in characteristics) {
          //   // List<int> value = await c.read();
          //   print(c);
          // }
        });

        // discoverServices(); // Function to request Services & find required service & char
      }
      if (deviceState == BluetoothDeviceState.disconnected) {
        // disconnect();  // function to handle disconnect event
        // myDevice = null;
        disconnectDevice(device);
        print("-----------Device Disconnected---------");
        connectingDevice = null;
      }
    });

    setState(() {
      _active = true;
      _connectedDevice.add(device);
    });
  }

  Future<void> _getService(List<BluetoothService> services) async {
    Map<Guid, Guid> characterServices = {
      Guid("cdeacb80-5235-4c07-8846-93a37ee6b86d"): Guid("cdeacb81-5235-4c07-8846-93a37ee6b86d"),
      Guid("49535343-fe7d-4ae5-8fa9-9fafd205e455"): Guid("49535343-1e4d-4bd9-ba61-23c647249616")
    };
    BluetoothService service = services.where((s) => configServices.contains(s.uuid)).first;
    List<BluetoothCharacteristic> characteristics = service.characteristics;
    if (characteristics.length > 0) {
      Guid? characterService = characterServices[service.uuid];
      BluetoothCharacteristic characteristic = characteristics.where((c) => c.uuid == characterService).first;
      await characteristic.setNotifyValue(true);
      // await characteristic.read();
      streamDataSubscription = characteristic.value.listen((value) {
        // print('valueIs ${value.toString()}');
        oximeterParser(characteristic.uuid, value);
      });
    }
    // await streamServiceSubscription.cancel();
  }

  void oximeterParser(Guid characterUuid, List<int> value) {
    if (value.isNotEmpty && characterUuid != null) {
      if (characterUuid == Guid("cdeacb81-5235-4c07-8846-93a37ee6b86d")) {
        if (value[0] == 0x81) {
          setState(() {
            spo2 = value[2];
            pulseRate = value[1];
            pi = (value[3] / 10);
            print('spo2 = ${spo2}, pulseRate = ${pulseRate}, pi = ${pi} %');
          });
        }
      } else if (characterUuid == Guid("49535343-1e4d-4bd9-ba61-23c647249616")) {
        setState(() {
          spo2 = value[4];
          pulseRate = value[3];
          pi = (value[0] / 10);
          print('spo2 below = ${spo2}, pulseRate = ${pulseRate}, pi = ${pi} %');
        });
      }
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    print("disconnect");
    print(device.name);
    await device.disconnect();
    if(streamDataSubscription != null) {
      await streamDataSubscription.cancel();
    }
    print("disconnected!");
    setState(() {
      _active = false;
      _connectedDevice.remove(device);
      pi = 0;
      spo2 = 0;
      pulseRate = 0;
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
                                  child: Text("Disconnect")),
                              Text("SpO2 ${spo2}, PulseRate ${pulseRate}, PI ${pi}")
                            ],
                          ))
                      .toList());
            })
      ],
    );
  }
}
