// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:path_provider/path_provider.dart';

// class TremorLogger extends StatefulWidget {
//   @override
//   _TremorLoggerState createState() => _TremorLoggerState();
// }

// class _TremorLoggerState extends State<TremorLogger> {
//   List<Map<String, dynamic>> sensorData = [];

//   @override
//   void initState() {
//     super.initState();
//     _startSensorListening();
//   }

//   void _startSensorListening() {
//     accelerometerEvents.listen((AccelerometerEvent event) {
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final data = {
//         'x': event.x,
//         'y': event.y,
//         'z': event.z,
//         'timestamp': timestamp,
//       };
//       sensorData.add(data);

//       // Optional: print every few samples
//       if (sensorData.length % 2 == 0) {
//         print('Accelerometer: $data');
//       }
//     });
//   }

//   Future<void> _saveData() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/tremor_log.json');
//     await file.writeAsString(jsonEncode(sensorData));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Sensor data saved to ${file.path}')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Tremor Logger'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _saveData,
//           ),
//         ],
//       ),
//       body: Center(
//         child: Text(
//           'Game would run here.\nSensor data logging in background.',
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';

class TremorLogger extends StatefulWidget {
  @override
  _TremorLoggerState createState() => _TremorLoggerState();
}

class _TremorLoggerState extends State<TremorLogger> {
  List<Map<String, dynamic>> sensorData = [];
  String latestReading = 'Waiting for data...';

  @override
  void initState() {
    super.initState();
    _startSensorListening();
  }

  void _startSensorListening() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final data = {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': timestamp,
      };
      sensorData.add(data);

      setState(() {
        latestReading =
            'X: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });

      
      print('Accelerometer: $data');
      
    });
  }

  Future<void> _saveData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tremor_log.json');
    await file.writeAsString(jsonEncode(sensorData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sensor data saved to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tremor Logger'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveData,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Game would run here.\nSensor data logging in background.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Text(
              'Latest Accelerometer Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              latestReading,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

