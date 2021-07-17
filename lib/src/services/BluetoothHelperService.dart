import 'dart:async';
import 'dart:math';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';

class BluetoothHelperService {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription? scanResultsStreamSubscription;
  List<Guid> _configServices = [
    Guid('cdeacb80-5235-4c07-8846-93a37ee6b86d'), // Jumper
    Guid('49535343-fe7d-4ae5-8fa9-9fafd205e455') // Berry
  ];
  // List<BluetoothDevice> connectedDevice = [];
  late StreamSubscription deviceStateSubscription;

  // late BluetoothDevice? connectingDevice;
  BehaviorSubject<BluetoothDevice?> _connectingDevice = BehaviorSubject.seeded(null);
  Stream<BluetoothDevice?> get connectingDevice$ => _connectingDevice.stream;

  BehaviorSubject<List<BluetoothDevice>> _connectedDevices = BehaviorSubject.seeded([]);
  Stream<List<BluetoothDevice>> get connectedDevices$ => _connectedDevices.stream;
  List<BluetoothDevice>? get connectedDevices => _connectedDevices.value;

  late StreamSubscription? streamDataSubscription;
  String lastedId = "00:A0:50:32:8C:C1";

  Map<String, dynamic> _myOximeterData = {
    'spO2' : 0,
    'pulseRate' : 0,
    'pi' : 0.0
  };
  BehaviorSubject<Map<String, dynamic>> _oximeterData = BehaviorSubject.seeded({
                                                                                'spO2' : 0,
                                                                                'pulseRate' : 0,
                                                                                'pi' : 0.0
                                                                              });
  Stream<Map<String, dynamic>> get oximeterData$ => _oximeterData.stream;

  // int spo2 = 0;
  // int pulseRate = 0;
  // double pi = 0;

  void startScan() {
    // _scaning = true;
// Start scanning
    flutterBlue.startScan(
        timeout: Duration(seconds: 4), withServices: _configServices);

// Listen to scan results
    scanResultsStreamSubscription = flutterBlue.scanResults.listen((results) {
// do something with scan results
      for (ScanResult r in results) {
        print('${r.device.name} found! id: ${r.device.id}, rssi: ${r.rssi}');
      }
    });
// Stop scanning
//   flutterBlue.stopScan();
  }

  void connectLastedDevice() {
    stopScan();

    String deviceId = lastedId;
    flutterBlue.startScan(timeout: Duration(seconds: 4), withServices: _configServices);

    scanResultsStreamSubscription = flutterBlue.scanResults.listen((results) async {
      for (ScanResult r in results) {
       print("IDDD" + r.device.id.id);
      }

      if(results.where((x) => x.device.id.id == deviceId).isNotEmpty){
        print("พบอุปกรณ์");
        BluetoothDevice device = results.singleWhere((x) => x.device.id.id == deviceId).device;
        await connectDevice(device);
        print("เชื่อมต่อแล้ว");

      }
      else{
        print("ไม่พบอุปกรณ์");
      }
      // for (ScanResult r in results) {
      //   if(r.device.id.id  == deviceId){
      //     await connectDevice(r.device);
      //   }
      // }
    });

    // stopScan();
  }

  void stopScan() {
// Stop scanning
    flutterBlue.stopScan();
    if(scanResultsStreamSubscription != null){
      scanResultsStreamSubscription!.cancel();
    }
  }


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

    deviceStateSubscription = device.state.listen((deviceState) async {
      if (deviceState == BluetoothDeviceState.connected) {
        print("-----------Device Connected---------");
        // connectingDevice = device;
        _connectingDevice.add(device);
        List<BluetoothService> services = await device.discoverServices();
        services.forEach((service) async {
          // do something with service
          print("connecting device list service");
          print("uuid : " + service.uuid.toString());
          print("char : " + service.characteristics.toString());

          // discover services
          await _getService(services);

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
        // connectingDevice = null;
        _connectingDevice.add(null);
      }
    });

    // setState(() {
    //   _connectedDevice.add(device);
    _connectedDevices.add([device]);
    // });
  }

  Future<void> _getService(List<BluetoothService> services) async {
    Map<Guid, Guid> characterServices = {
      Guid("cdeacb80-5235-4c07-8846-93a37ee6b86d"): Guid("cdeacb81-5235-4c07-8846-93a37ee6b86d"),
      Guid("49535343-fe7d-4ae5-8fa9-9fafd205e455"): Guid("49535343-1e4d-4bd9-ba61-23c647249616")
    };
    BluetoothService service = services.singleWhere((s) => _configServices.contains(s.uuid));
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
          // setState(() {
          //   spo2 = value[2];
          //   pulseRate = value[1];
          //   pi = (value[3] / 10);
          // });

          // print('spo2 = ${spo2}, pulseRate = ${pulseRate}, pi = ${pi} %');

            _myOximeterData["spO2"] = value[2];
            _myOximeterData["pulseRate"] = value[1];
            _myOximeterData["pi"] = (value[3] / 10);
            _oximeterData.add(_myOximeterData);
            print(_myOximeterData);
        }
      } else if (characterUuid == Guid("49535343-1e4d-4bd9-ba61-23c647249616")) {
        // setState(() {
        //   spo2 = value[4];
        //   pulseRate = value[3];
        //   pi = (value[0] / 10);
        // print('spo2 below = ${spo2}, pulseRate = ${pulseRate}, pi = ${pi} %');
        // });

        _myOximeterData["spO2"] = value[4];
        _myOximeterData["pulseRate"] = value[3];
        _myOximeterData["pi"] = (value[0] / 10);
        _oximeterData.add(_myOximeterData);
        print(_myOximeterData);
      }
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    print("disconnect");
    print(device.name);
    await device.disconnect();
    if(streamDataSubscription != null) {
      await streamDataSubscription?.cancel();
    }
    print("disconnected!");
    // setState(() {
    // connectedDevices?.remove(device);
    _connectedDevices.add([]);
    // pi = 0;
    // spo2 = 0;
    // pulseRate = 0;
    // });

    _myOximeterData["spO2"] = 0;
    _myOximeterData["pulseRate"] = 0;
    _myOximeterData["pi"] = 0.0;
    _oximeterData.add(_myOximeterData);
    print(_myOximeterData);
  }
}

BluetoothHelperService bluetoothHelperService = new BluetoothHelperService();