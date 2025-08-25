import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(TremorApp());
}

class TremorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tremor Detector',
      home: TremorHomePage(),
    );
  }
}

class TremorHomePage extends StatefulWidget {
  @override
  _TremorHomePageState createState() => _TremorHomePageState();
}

class _TremorHomePageState extends State<TremorHomePage> {
  List<Offset?> points = [];
  List<Map<String, dynamic>> traceData = [];

  void _clear() {
    setState(() {
      points.clear();
      traceData.clear();
    });
  }

  Future<void> _saveData() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/tremor_data.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(traceData));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved to: $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tremor Detection'),
        actions: [
          IconButton(icon: Icon(Icons.delete), onPressed: _clear),
          IconButton(icon: Icon(Icons.save), onPressed: _saveData),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final position = details.localPosition;
                  final timestamp = DateTime.now().millisecondsSinceEpoch;

                  setState(() {
                    points.add(position);
                    traceData.add({
                      'x': position.dx,
                      'y': position.dy,
                      'timestamp': timestamp,
                    });
                    print('Point: x=${position.dx}, y=${position.dy}, time=$timestamp');
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    points.add(null); // To break the line
                  });
                },
                child: CustomPaint(
                  painter: TracePainter(points),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Draw with your finger or mouse',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Tap and drag on the area above.\nTap 🗑 to clear or 💾 to save.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class TracePainter extends CustomPainter {
  final List<Offset?> points;
  TracePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
