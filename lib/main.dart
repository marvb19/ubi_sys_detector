import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert' show utf8;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Ubiquitous System Lab Application',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'Detector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String ble_text = "";

  //0: other activity
  //1: lift
  //2: stair
  int _activity = 1;

  void _switchActivity() {
    setState(() {
      _activity= (_activity + 1) % 3;
    });
  }



  Widget activityIndicator(){
    switch(_activity){
      case 1:
        return const Icon(Icons.elevator, size: 350,);
      case 2:
        return const Icon(Icons.stairs, size: 350,);
      default:
        return const Icon(Icons.close, size: 350,);
    }
  }

  //BLE Stuff
  final String SERVICE_UUID= "12345678-9abc-def0-1234-56789abcdef0";
  final String CHARACTERISTIC_UUID = "12345678-9abc-def0-1234-56789abcdef1";
  final String TARGET_DEVICE_NAME = "ESP32-BLE-Server";

  FlutterBlue flutterBlue = FlutterBlue.instance;
  late StreamSubscription<ScanResult> scanSubscription;

  late BluetoothDevice targetDevice;
  late BluetoothCharacteristic targetCharacteristic;

  String connetionText = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startScan();

  }

  startScan(){
  setState(() {
    connetionText = "Start scanning";
  });

  scanSubscription = flutterBlue.scan().listen((scanResult){
    if(scanResult.device.name == TARGET_DEVICE_NAME) {
      print("DEVICE found");
      stopScan();
      setState(() {
        connetionText = "Found Target Device";
      });
      targetDevice = scanResult.device;
      connectToDevice();
    }
  }, onDone: () => stopScan());
  }

  stopScan(){
    scanSubscription.cancel();
    //scanSubscription = null;
  }

  connectToDevice() async{
    if(targetDevice == null) return;

    setState(() {
      connetionText = "Device connecting";
    });

    await targetDevice.connect();
    print("DEVICE CONNECTED");
    setState(() {
      connetionText = "Device Connected";
    });
    discoverServices();
  }

  disconnectFromDevice(){
    if(targetDevice == null) return;

    targetDevice.disconnect();
    setState(() {
      connetionText = "Device Disconnected";
    });
  }

  discoverServices() async{
    if(targetDevice == null) return;
    
    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      //do something with services
      if(service.uuid.toString() == SERVICE_UUID){
        service.characteristics.forEach((characteristic) {
          if(characteristic.uuid.toString() == CHARACTERISTIC_UUID){
            targetCharacteristic = characteristic;
            //writeData("Hi there ESP32");
            setState(() {
              connetionText = "All Ready with ${targetDevice.name}";
            });
          }
        });
      }
    });
  }

  writeData(String data) async{
    if(targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes);
  }

  readData() async{
    if(targetCharacteristic == null) return;

    List<int> value = await targetCharacteristic.read();
    print(utf8.decode(value));
    ble_text = utf8.decode(value);
  }

  notifyData() async{
    if(targetCharacteristic == null) return;
    await targetCharacteristic.setNotifyValue(true);
    targetCharacteristic.value.listen((value) {
      setState(() {
        ble_text = utf8.decode(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            activityIndicator(),
            Text(connetionText),
            Text(ble_text),
            TextButton(
              onPressed: readData,
              child: const Text('Read'),
            ),
            TextButton(
              onPressed: () => writeData(_activity.toString()),
              child: const Text('Write'),
            ),
            TextButton(
              onPressed: notifyData,
              child: const Text('Notify'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        //onPressed: _switchActivity,
        onPressed: _switchActivity,
        tooltip: 'Increment',
        child: const Icon(Icons.cameraswitch),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

