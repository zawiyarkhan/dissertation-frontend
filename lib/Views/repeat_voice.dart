import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
 

class RepeatAfterMeScreen extends StatefulWidget {
  const RepeatAfterMeScreen({super.key});

  @override
  State<RepeatAfterMeScreen> createState() => _RepeatAfterMeScreenState();
}

class _RepeatAfterMeScreenState extends State<RepeatAfterMeScreen> {
  final List<String> _wordsToRepeat = [
    "Hello",
    "Butterfly",
    "Elephant",
    "Mississippi",
    "Unbelievable",
    "Statistics",
    "Consciousness",
    "Phenomenon",
    "Rhetorical",
    "Quintessential",
  ];

  int _currentWordIndex = 0;
  final AudioRecorder  _audioRecorder = AudioRecorder();
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPermissionsGranted = false;
  String _message = "Press 'Speak' to hear the word.";
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initTts();
  }

  // Initialize Text-to-Speech
  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5); // Adjust speech rate as needed
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  // Request microphone permissions
  Future<void> _requestPermissions() async {
  final status = await Permission.microphone.request();

  setState(() {
    _isPermissionsGranted = status.isGranted;
    _message = _isPermissionsGranted
        ? "Permissions granted. Press 'Speak' to hear the word."
        : "Microphone permission denied. Please enable it in settings.";
  });
}


  // Speak the current word using TTS
  Future<void> _speakWord() async {
    if (_isPermissionsGranted) {
      setState(() {
        _message = "Speaking: ${_wordsToRepeat[_currentWordIndex]}";
      });
      await _flutterTts.speak(_wordsToRepeat[_currentWordIndex]);
      setState(() {
        _message = "Listen. Now press 'Record' to repeat.";
      });
    } else {
      _message = "Microphone permission not granted.";
      _requestPermissions(); // Re-request if denied
    }
  }

  // Start recording user's voice
  Future<void> _startRecording() async {
    if (!_isPermissionsGranted) {
      _message = "Microphone permission not granted.";
      _requestPermissions();
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          path: filePath,
          RecordConfig(
          encoder: AudioEncoder.aacLc
        ),);
        setState(() {
          _isRecording = true;
          _recordedFilePath = null; // Clear previous path
          _message = "Recording... Speak now!";
        });
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
      setState(() {
        _message = "Error starting recording: $e";
      });
    }
  }

  // Stop recording user's voice
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
          _message = "Recording stopped. File saved: ${path.split('/').last}";
        });
        _sendAudioToBackend(path); // Simulate sending to backend
      } else {
        setState(() {
          _isRecording = false;
          _message = "Recording stopped, but no file path returned.";
        });
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      setState(() {
        _isRecording = false;
        _message = "Error stopping recording: $e";
      });
    }
  }

  // Simulate sending audio to a backend
  Future<void> _sendAudioToBackend(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final uri = Uri.parse('http://192.168.0.39:8000/voice/upload'); // Replace with your endpoint

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'voice_file',
            bytes,
            filename: 'voice_file.m4a',
            contentType: MediaType('audio', 'm4a'), // optionally use: import 'package:http_parser/http_parser.dart';
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint("Audio uploaded successfully");
        setState(() {
          _message = "Audio uploaded successfully!";
        });
      } else {
        debugPrint("Upload failed: ${response.statusCode} - ${response.body}");
        setState(() {
          _message = "Audio upload failed: ${response.statusCode}";
        });
      }

      // Delete the file after sending
      await file.delete();
      debugPrint("Temporary file deleted after sending");
    } else {
      debugPrint("File does not exist: $filePath");
    }
  } catch (e) {
    debugPrint("Error uploading audio: $e");
    setState(() {
      _message = "Error uploading audio: $e";
    });
  }
}

  // Move to the next word in the list
  void _nextWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _wordsToRepeat.length;
      _recordedFilePath = null;
      _isRecording = false;
      _message = "Press 'Speak' to hear the word.";
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repeat After Me'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Current Word Display
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      const Text(
                        'Repeat This Word:',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _wordsToRepeat[_currentWordIndex],
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Message Display
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: _isRecording ? Colors.red : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speak Button
                  ElevatedButton.icon(
                    onPressed: _isRecording ? null : _speakWord,
                    icon: const Icon(Icons.volume_up, size: 28),
                    label: const Text('Speak', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                  ),
                  // Record Button
                  ElevatedButton.icon(
                    onPressed: _isPermissionsGranted
                        ? (_isRecording ? _stopRecording : _startRecording)
                        : null,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 28,
                    ),
                    label: Text(
                      _isRecording ? 'Stop Recording' : 'Record',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _isRecording ? Colors.red : Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Next Word Button
              ElevatedButton.icon(
                onPressed: _isRecording ? null : _nextWord,
                icon: const Icon(Icons.arrow_forward_ios, size: 28),
                label: const Text('Next Word', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

