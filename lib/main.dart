import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:oximeter_app/widgets.dart';

void main() {
  runApp(MyApp());
}

FlutterBlue flutterBlue = FlutterBlue.instance;
StreamSubscription? _scanResultsStream;
bool _scaning = false;
List<Guid> configServices = [
  Guid('cdeacb80-5235-4c07-8846-93a37ee6b86d'), // Jumper
  Guid('49535343-fe7d-4ae5-8fa9-9fafd205e455') // Berry
];

void scanBlutooth(){
  _scaning = true;
  // Start scanning
  flutterBlue.startScan(timeout: Duration(seconds: 4), withServices: configServices);

// Listen to scan results
  _scanResultsStream = flutterBlue.scanResults.listen((results) {
    // do something with scan results
    for (ScanResult r in results) {
      print('${r.device.name} found! id: ${r.device.id}, rssi: ${r.rssi}');
    }
  });
  // _scaning = false;

// Stop scanning
//   flutterBlue.stopScan();
}

void stopScan(){
  // Stop scanning
  flutterBlue.stopScan();
  _scanResultsStream!.cancel();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Blutooth Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<BluetoothState>(
              stream: flutterBlue.state,
                initialData: BluetoothState.unknown,
                builder: (context, snapshot){
                  if(snapshot.data == BluetoothState.on){
                    return Column(
                        children: [
                          Text("Bluetooth Is On!"),
                          Text("press search button to scan device"),
                          DevicesScan(),
                        ]);
                  }else{
                    return Text("Please turn on Bluetooth");
                  }
                }
            ),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: flutterBlue.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => scanBlutooth());
                    // .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
      // FloatingActionButton(
      //   onPressed: scanBlutooth,
      //   tooltip: 'Scan',
      //   child: _scaning == true ? Icon(Icons.stop) :  Icon(Icons.search),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
