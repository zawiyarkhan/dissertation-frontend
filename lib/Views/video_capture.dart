import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:video_player/video_player.dart'; // For playing back recorded video

import 'package:path/path.dart' as path;


class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  String? _videoFilePath;
  Timer? _timer;
  int _start = 10; // 30 seconds for video recording
  VideoPlayerController? _videoPlayerController;
  bool _showVideoPreview = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera and microphone permissions
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showMessage("No cameras found on this device.");
        return;
      }

      // Find a back camera, or use the first available
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        frontCamera ?? _cameras![0], // Use back camera if available, else first
        ResolutionPreset.medium, // Adjust resolution as needed
        enableAudio: true,
      );

      _cameraController!.addListener(() {
        if (mounted) setState(() {});
        if (_cameraController!.value.hasError) {
          _showMessage('Camera error: ${_cameraController!.value.errorDescription}');
        }
      });

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } on CameraException catch (e) {
        debugPrint("Camera initialization error: $e");
        _showMessage("Error initializing camera: ${e.description}");
      }
    } else {
      _showMessage("Camera or Microphone permission denied. Please enable them in settings.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startVideoRecording() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      _videoFilePath = null; // Clear any previous video
      _showVideoPreview = false; // Hide preview
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }

      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _start = 30; // Reset timer
      });
      _startTimer();
      _showMessage("Recording started for 30 seconds.");
    } on CameraException catch (e) {
      debugPrint("Error starting video recording: $e");
      _showMessage("Error starting video recording: ${e.description}");
    }
  }

  void _stopVideoRecording() async {
    if (!_isRecording || _cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      _timer?.cancel(); // Stop the timer
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoFilePath = videoFile.path;
      });
      _showMessage("Video recording stopped. File saved: ${videoFile.path.split('/').last}");
      _sendVideoToBackend(videoFile.path);
      _playRecordedVideo(videoFile.path); // Play back for user feedback
    } on CameraException catch (e) {
      debugPrint("Error stopping video recording: $e");
      _showMessage("Error stopping video recording: ${e.description}");
    }
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _stopVideoRecording(); // Automatically stop after 30 seconds
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  Future<void> _playRecordedVideo(String filePath) async {
    _videoPlayerController = VideoPlayerController.file(File(filePath));
    await _videoPlayerController!.initialize();
    setState(() {
      _showVideoPreview = true;
    });
    _videoPlayerController!.play();
  }

  // Simulate sending video to a backend
  Future<void> _sendVideoToBackend(String filePath) async {
  final uri = Uri.parse("http://192.168.0.39:8000/blink/upload"); // Update this
  final request = http.MultipartRequest('POST', uri);
  final videoFile = File(filePath);

  if (!videoFile.existsSync()) {
    debugPrint("Video file not found at $filePath");
    return;
  }

  try {
    request.files.add(
      await http.MultipartFile.fromPath(
        'blink_file', // field name expected by your backend
        filePath,
        contentType: MediaType('video', 'mp4'), // Assuming mp4
      ),
    );

    debugPrint("Uploading video: ${path.basename(filePath)} to $uri");

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      debugPrint("Video uploaded successfully: $responseData");
      _showMessage("Video uploaded successfully!");
    } else {
      final responseData = await response.stream.bytesToString();
      debugPrint("Video upload failed with status: ${response.statusCode}, body: $responseData");
      _showMessage("Video upload failed.");
    }
  } catch (e) {
    debugPrint("Error uploading video: $e");
    _showMessage("Error uploading video.");
  }
}

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Recording'),
        centerTitle: true,
        backgroundColor: Colors.purple,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isCameraInitialized
          ? Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Preview or Video Player
                      _showVideoPreview && _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController!),
                            )
                          : CameraPreview(_cameraController!),
                      // Recording Indicator
                      if (_isRecording)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, color: Colors.white, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  '${_start}s',
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        _isRecording
                            ? 'Recording... $_start seconds remaining'
                            : (_videoFilePath != null
                                ? 'Video recorded. Ready to record again.'
                                : 'Press record to start 30-second video.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: _isRecording ? Colors.red : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          size: 30,
                        ),
                        label: Text(
                          _isRecording ? 'Stop Recording' : 'Start 30s Recording',
                          style: const TextStyle(fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _isRecording ? Colors.red : Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          minimumSize: const Size(double.infinity, 70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}

