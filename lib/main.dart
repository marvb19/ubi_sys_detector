import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
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
  String bleText = "";

  //0: other activity
  //1: lift
  //2: stair
  int _activity = 0;

  static const Color iconColor = Colors.blue;

  Widget activityIndicator() {
    const double iconSize = 350;
    switch (_activity) {
      case 1:
        bleText = "Lift";
        return const Icon(
          color: iconColor,
          Icons.elevator,
          size: iconSize,
        );
      case 2:
        bleText = "Stair";
        return const Icon(
          color: iconColor,
          Icons.stairs,
          size: iconSize,
        );
      default:
        bleText = "other activity";
        return const Icon(
          color: iconColor,
          Icons.close,
          size: iconSize,
        );
    }
  }

  //BLE Stuff
  final String SERVICE_UUID = "12345678-9abc-def0-1234-56789abcdef0";
  final String CHARACTERISTIC_UUID = "12345678-9abc-def0-1234-56789abcdef1";
  final String TARGET_DEVICE_NAME = "ESP32-BLE-Server";

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  late StreamSubscription<ScanResult>? scanSubscription;

  late BluetoothDevice targetDevice;
  late BluetoothCharacteristic targetCharacteristic;

  String connectionStateText = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startScan();
  }

  startScan() {
    setState(() {
      connectionStateText = "Start scanning";
    });

    scanSubscription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name == TARGET_DEVICE_NAME) {
        //print("DEVICE found");
        stopScan();
        setState(() {
          connectionStateText = "Found Target Device";
        });
        targetDevice = scanResult.device;
        connectToDevice();
      }
    }, onDone: () => stopScan());
  }

  stopScan() {
    flutterBlue.stopScan();
    scanSubscription?.cancel();

    scanSubscription = null;
  }

  connectToDevice() async {
    if (targetDevice == null) return;

    setState(() {
      connectionStateText = "Device connecting";
    });

    await targetDevice.connect();
    print("DEVICE CONNECTED");
    setState(() {
      connectionStateText = "Device Connected";
    });
    discoverServices();
  }

  disconnectFromDevice() {
    if (targetDevice == null) return;

    targetDevice.disconnect();

    setState(() {
      connectionStateText = "Device Disconnected";
    });
  }

  discoverServices() async {
    if (targetDevice == null) return;

    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristic;
            //writeData("Hi there ESP32");
            notifyData();
            setState(() {
              connectionStateText = "All Ready with ${targetDevice.name}";
            });
          }
        });
      }
    });
  }

  writeData() async {
    if (targetCharacteristic == null) return;

    String data = _activity.toString();
    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes);
  }

  readData() async {
    if (targetCharacteristic == null) return;

    List<int> value = await targetCharacteristic.read();
    setState(() {
      bleText = utf8.decode(value);
      _activity =
          int.parse(utf8.decode(value).replaceAll(RegExp(r'[^0-9]'), ''));
      print(_activity);
    });
  }

  notifyData() async {
    if (targetCharacteristic == null) return;
    await targetCharacteristic.setNotifyValue(true);
    targetCharacteristic.value.listen((value) {
      setState(() {
        _activity =
            int.parse(utf8.decode(value).replaceAll(RegExp(r'[^0-9]'), ''));
      });
    });
  }

  //END of BLE Stuff

  ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      fixedSize: Size(105, 30),
      foregroundColor: Colors.black,
      backgroundColor: Colors.blue);

  static const TextStyle textStyle =
      TextStyle(color: Colors.blue, fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        foregroundColor: Colors.black,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              //crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                activityIndicator(),
              ],
            ),
            SizedBox(height: 80),
            Row(
              //crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: disconnectFromDevice,
                  child: const Text('Disconnect'),
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: stopScan,
                  child: const Text('Stop'),
                ),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: startScan,
                  child: const Text('Start'),
                ),
              ],
            ),
            SizedBox(height: 25),
            Row(
              //crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(connectionStateText, style: textStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
