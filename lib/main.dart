import 'package:alzheimer_app/Views/game_tremor.dart';
import 'package:alzheimer_app/Views/repeat_voice.dart';
import 'package:alzheimer_app/Views/tremor_accelerometer.dart';
import 'package:alzheimer_app/Views/tremors.dart';
import 'package:alzheimer_app/Views/video_capture.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// void main() {
//   runApp(MaterialApp(
//     home: Scaffold(
//       appBar: AppBar(title: Text('Test App')),
//       body: Center(child: Text('If you see this, your UI is fine')),
//     ),
//   ));
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: VideoRecordingScreen()
    );
  }
}

