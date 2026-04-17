import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuro_app/helpers/test_result_helper.dart';
import 'package:neuro_app/screens/neurology_report_screen.dart';

class EyeTrackingTest extends StatefulWidget {
  const EyeTrackingTest({super.key});

  @override
  State<EyeTrackingTest> createState() => _EyeTrackingTestState();
}

class _EyeTrackingTestState extends State<EyeTrackingTest>
    with SingleTickerProviderStateMixin {

  // CAMERA
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  late List<CameraDescription> _cameras;
  int _selectedCameraIndex = 0;

  // ML KIT
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // DOT ANIMATION
  late AnimationController _dotController;

  // TRACKING DATA
  Offset? _eyePosition;
  Offset _dotPosition = Offset.zero;
  Offset _previousDotPosition = Offset.zero;

  int totalTracks = 0;
  int successfulTracks = 0;
  List<double> latencies = [];
  List<Offset> eyeHistory = [];

  // Frame throttling to avoid overprocessing
  DateTime _lastFrameTime = DateTime.now();
  static const Duration _frameThrottleDuration = Duration(milliseconds: 100);

  DateTime? dotMovedTime;
  DateTime? testStartTime;
  static const Duration _maxTestDuration = Duration(seconds: 30);
  static const int _maxEyeHistorySize = 300; // ~3 seconds at 100ms throttle

  bool started = false;
  bool completed = false;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();

    // Only initialize camera on mobile platforms
    if (!kIsWeb) {
      _initCamera();
    }

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_updateDot);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Find front camera (for eye tracking)
    int frontCameraIndex = -1;
    for (int i = 0; i < _cameras.length; i++) {
      print('Camera $i: ${_cameras[i].name} - Lens: ${_cameras[i].lensDirection}');
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        frontCameraIndex = i;
        print('Front camera found at index: $i');
      }
    }

    // If front camera not found, use first available
    if (frontCameraIndex == -1) {
      print('Front camera not found, using first camera');
      frontCameraIndex = 0;
    }

    _selectedCameraIndex = frontCameraIndex;
    print('Using camera index: $_selectedCameraIndex');
    await _switchCamera(_selectedCameraIndex);
  }

  Future<void> _switchCamera(int cameraIndex) async {
    if (_cameras.isEmpty || cameraIndex >= _cameras.length) return;

    // Dispose old controller
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();

    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = cameraIndex;
    });

    // Initialize new camera
    _cameraController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream((image) {
      _processCameraImage(image);
    });

    setState(() => _isCameraInitialized = true);
  }

  void _processCameraImage(CameraImage image) async {
    // Throttle frame processing to avoid lag
    final now = DateTime.now();
    if (now.difference(_lastFrameTime) < _frameThrottleDuration) {
      return;
    }
    _lastFrameTime = now;

    // Prevent concurrent frame processing
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    try {
      final inputImage = _inputImageFromCamera(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        final leftEye = face.landmarks[FaceLandmarkType.leftEye];
        final rightEye = face.landmarks[FaceLandmarkType.rightEye];

        if (leftEye != null && rightEye != null) {
          // Calculate eye center in camera frame coordinates
          Offset eyeCenter = Offset(
            (leftEye.position.x + rightEye.position.x) / 2,
            (leftEye.position.y + rightEye.position.y) / 2,
          );

          // Map camera coordinates to screen coordinates
          // Scale to match the dot container (300px height)
          final scaleFactor = 300 / image.height;
          final mappedEye = Offset(
            eyeCenter.dx * scaleFactor,
            eyeCenter.dy * scaleFactor,
          );

          setState(() {
            _eyePosition = mappedEye;
            // Limit eye history to prevent memory growth
            if (eyeHistory.length >= _maxEyeHistorySize) {
              eyeHistory.removeAt(0);
            }
            eyeHistory.add(mappedEye);
          });

          _analyzeTracking();

          // Check if test should end (30 second limit)
          if (started && testStartTime != null) {
            if (DateTime.now().difference(testStartTime!) > _maxTestDuration) {
              _endTest();
            }
          }
        }
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    try {
      final buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final byteData = buffer.done();
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      print('Error creating InputImage: $e');
      return null;
    }
  }

  void _updateDot() {
    final angle = _dotController.value * 2 * pi;

    if (mounted) {
      setState(() {
        _previousDotPosition = _dotPosition;
        _dotPosition = Offset(
          150 + 100 * cos(angle),
          150 + 100 * sin(angle),
        );

        // Track when dot actually moves (threshold: 5px movement)
        final distance = (_dotPosition - _previousDotPosition).distance;
        if (distance > 5) {
          dotMovedTime = DateTime.now();
        }
      });
    }
  }

  void _startTest() {
    setState(() {
      started = true;
      testStartTime = DateTime.now();
      totalTracks = 0;
      successfulTracks = 0;
      latencies.clear();
      eyeHistory.clear();
    });
    _dotController.repeat();
  }

  void _endTest() {
    setState(() {
      started = false;
      completed = true;
    });
    _dotController.stop();
  }

  void _resetTest() {
    setState(() {
      completed = false;
      started = false;
      totalTracks = 0;
      successfulTracks = 0;
      latencies.clear();
      eyeHistory.clear();
      _eyePosition = null;
    });
  }

  void _analyzeTracking() {
    if (_eyePosition == null) return;

    final distance = (_eyePosition! - _dotPosition).distance;

    totalTracks++;

    if (distance < 80) {
      successfulTracks++;

      if (dotMovedTime != null) {
        final latency = DateTime.now()
            .difference(dotMovedTime!)
            .inMilliseconds;
        latencies.add(latency.toDouble());
      }
    }
  }

  double get accuracy =>
      totalTracks == 0 ? 0 : (successfulTracks / totalTracks) * 100;

  double get avgLatency =>
      latencies.isEmpty ? 0 : latencies.reduce((a, b) => a + b) / latencies.length;

  double get stability {
    if (eyeHistory.length < 2) return 0;
    double meanX =
        eyeHistory.map((e) => e.dx).reduce((a, b) => a + b) / eyeHistory.length;
    double variance = eyeHistory
            .map((e) => pow(e.dx - meanX, 2))
            .reduce((a, b) => a + b) /
        eyeHistory.length;
    return variance;
  }

  String get riskLevel {
    double score = 0;

    if (avgLatency > 300) score += 30;
    if (accuracy < 60) score += 40;
    if (stability > 5000) score += 30;

    if (score < 30) return "Normal";
    if (score < 60) return "Mild Concern";
    return "High Risk";
  }

  Future<void> _storeTestResult() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Calculate eye tracking score (0-100)
        double score = 100.0;
        if (avgLatency > 300) score -= 30;
        if (accuracy < 60) score -= 40;
        if (stability > 5000) score -= 30;

        await TestResultHelper.storeEyeTrackingTestResult(
          userId: currentUser.uid,
          accuracyPercentage: accuracy.clamp(0.0, 100.0),
          trackingQuality: {
            'averageLatency': avgLatency,
            'accuracy': accuracy,
            'stability': stability,
            'calibrationStatus': 'Complete',
          },
        );
        print('Eye tracking test result stored: Accuracy $accuracy%');
      }
    } catch (e) {
      print('Error storing test result: $e');
    }
  }

  void _viewReport() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    if (!kIsWeb) {
      _faceDetector.close();
    }
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Eye tracking test is not supported on web
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text("Neurological Eye Test")),
        body: const Center(
          child: Text(
            "Eye Tracking Test is not available on web.\nPlease use a mobile device.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Neurological Eye Test"),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: () {
                int nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
                _switchCamera(nextIndex);
              },
              tooltip: "Switch Camera",
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_cameraController!),
          ),
          if (!started)
            ElevatedButton(
              onPressed: _startTest,
              child: const Text("Start Test"),
            ),
          if (started)
            Container(
              height: 300,
              color: Colors.black,
              child: Stack(
                children: [
                  Positioned(
                    left: _dotPosition.dx,
                    top: _dotPosition.dy,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (started)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text("Accuracy: ${accuracy.toStringAsFixed(1)}%"),
                  Text("Latency: ${avgLatency.toStringAsFixed(0)} ms"),
                  Text("Stability: ${stability.toStringAsFixed(0)}"),
                  Text("Risk: $riskLevel",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    "⚠️ This is not a medical diagnosis. For screening purposes only.",
                    style: TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _storeTestResult();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}