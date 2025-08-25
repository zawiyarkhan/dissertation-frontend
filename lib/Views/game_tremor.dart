import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;





class TremorGame extends StatefulWidget {
  @override
  _TremorGameState createState() => _TremorGameState();
}

class _TremorGameState extends State<TremorGame> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double playerX = 0;
  double boxY = -1;
  double boxX = 0;
  double boxSpeed = 0.02;
  List<Map<String, dynamic>> sensorData = [];

  @override
  void initState() {
    super.initState();
    _startSensorLogging();
    _spawnBox();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..addListener(_updateGame);
    controller.forward();
  }


    Future<void> _sendDataToBackend() async {
  final url = Uri.parse('http://192.168.0.39:8000/accelerometer'); // Replace with your actual endpoint

  // Convert timestamps to ISO8601 strings
  final convertedData = sensorData.map((entry) {
    return {
      'x': entry['x'],
      'y': entry['y'],
      'z': entry['z'],
      'timestamp': DateTime.fromMillisecondsSinceEpoch(entry['timestamp']).toIso8601String(),
    };
  }).toList();

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(convertedData), // Send list of AccelerometerCreate objects
    );

    if (response.statusCode == 200) {
      print('Data sent successfully');
    } else {
      print('Failed to send data: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    print('Error sending data: $e');
  }
}





  void _startSensorLogging() {
    accelerometerEvents.listen((event) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      sensorData.add({
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': timestamp,
      });
      print('Accelerometer -> x: ${event.x}, y: ${event.y}, z: ${event.z}, time: $timestamp');
    });
  }

  void _spawnBox() {
    final random = Random();
    boxX = (random.nextDouble() * 2) - 1; // between -1 and 1
    boxY = -1;
  }

  void _updateGame() {
    setState(() {
      boxY += boxSpeed;
      if (boxY >= 1) {
        _spawnBox();
      }

      // Collision detection
      if ((boxY > 0.8) &&
          (boxX - playerX).abs() < 0.2) {
        controller.stop();
        _sendDataToBackend();
        _showGameOver();
      }
    });
  }

  void _movePlayer(double direction) {
    setState(() {
      playerX += direction;
      if (playerX < -1) playerX = -1;
      if (playerX > 1) playerX = 1;
    });
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Game Over'),
        content: Text('You were hit!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.reset();
              controller.forward();
              sensorData.clear();
              _spawnBox();
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildPlayer() {
    return Align(
      alignment: Alignment(playerX, 0.9),
      child: Container(width: 50, height: 50, color: Colors.blue),
    );
  }

  Widget _buildFallingBox() {
    return Align(
      alignment: Alignment(boxX, boxY),
      child: Container(width: 40, height: 40, color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _movePlayer(details.delta.dx / MediaQuery.of(context).size.width * 2);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Tremor Game')),
        body: Stack(
          children: [
            _buildPlayer(),
            _buildFallingBox(),
          ],
        ),
      ),
    );
  }
}
