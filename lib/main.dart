import 'package:flutter/material.dart';

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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _switchActivity,
        tooltip: 'Increment',
        child: const Icon(Icons.cameraswitch),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

