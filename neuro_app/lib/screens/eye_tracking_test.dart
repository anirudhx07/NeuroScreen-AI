import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
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

  // ML KIT (face mesh gives denser eye contour points than simple landmarks)
  final FaceMeshDetector _faceMeshDetector = FaceMeshDetector(
    option: FaceMeshDetectorOptions.faceMesh,
  );

  // DOT ANIMATION
  late AnimationController _dotController;

  // TRACKING DATA
  Offset? _eyePosition;
  Offset _dotPosition = Offset.zero;
  Offset _previousDotPosition = Offset.zero;

  // Calibration and smoothing state for stable real-time tracking
  bool _isCalibrating = false;
  DateTime? _calibrationStartTime;
  static const Duration _calibrationDuration = Duration(seconds: 3);
  double _minRawX = double.infinity;
  double _maxRawX = double.negativeInfinity;
  double _minRawY = double.infinity;
  double _maxRawY = double.negativeInfinity;
  static const double _smoothingAlpha = 0.35;

  int totalTracks = 0;
  int successfulTracks = 0;
  List<double> latencies = [];
  List<Offset> eyeHistory = [];

  // Frame throttling to avoid overprocessing
  DateTime _lastFrameTime = DateTime.now();
  static const Duration _frameThrottleDuration = Duration(milliseconds: 50);

  DateTime? dotMovedTime;
  DateTime? testStartTime;
  static const Duration _maxTestDuration = Duration(seconds: 30);
  static const int _maxEyeHistorySize = 300; // ~3 seconds at 100ms throttle

  bool started = false;
  bool completed = false;
  bool _isProcessingFrame = false;

  double get calibrationProgress {
    if (!_isCalibrating || _calibrationStartTime == null) return 1.0;
    final elapsed = DateTime.now().difference(_calibrationStartTime!);
    return (elapsed.inMilliseconds / _calibrationDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

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
      imageFormatGroup: ImageFormatGroup.yuv420,
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

      final meshes = await _faceMeshDetector.processImage(inputImage);
      if (meshes.isEmpty) return;

      final rawEye = _estimateEyeCenterFromMesh(meshes.first);
      if (rawEye == null) return;

      if (started) {
        _updateCalibration(rawEye);
      }

      final mappedEye = _mapRawEyeToTrackingCanvas(rawEye, imageSize: Size(image.width.toDouble(), image.height.toDouble()));
      final smoothedEye = (_eyePosition == null)
          ? mappedEye
          : _smoothOffset(_eyePosition!, mappedEye, _smoothingAlpha);

      setState(() {
        _eyePosition = smoothedEye;
        if (eyeHistory.length >= _maxEyeHistorySize) {
          eyeHistory.removeAt(0);
        }
        eyeHistory.add(smoothedEye);
      });

      if (started && !_isCalibrating) {
        _analyzeTracking();
      }

      // Check if test should end (30 second limit)
      if (started && testStartTime != null) {
        if (DateTime.now().difference(testStartTime!) > _maxTestDuration) {
          _endTest();
        }
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Offset? _estimateEyeCenterFromMesh(FaceMesh mesh) {
    final leftEyeContour = mesh.contours[FaceMeshContourType.leftEye] ?? [];
    final rightEyeContour = mesh.contours[FaceMeshContourType.rightEye] ?? [];

    if (leftEyeContour.isEmpty || rightEyeContour.isEmpty) {
      return null;
    }

    Offset centroid(List<FaceMeshPoint> points) {
      final sumX = points.fold<double>(0.0, (prev, p) => prev + p.x);
      final sumY = points.fold<double>(0.0, (prev, p) => prev + p.y);
      return Offset(sumX / points.length, sumY / points.length);
    }

    final leftCenter = centroid(leftEyeContour);
    final rightCenter = centroid(rightEyeContour);

    return Offset(
      (leftCenter.dx + rightCenter.dx) / 2,
      (leftCenter.dy + rightCenter.dy) / 2,
    );
  }

  void _updateCalibration(Offset rawEye) {
    if (!_isCalibrating || _calibrationStartTime == null) return;

    _minRawX = min(_minRawX, rawEye.dx);
    _maxRawX = max(_maxRawX, rawEye.dx);
    _minRawY = min(_minRawY, rawEye.dy);
    _maxRawY = max(_maxRawY, rawEye.dy);

    if (DateTime.now().difference(_calibrationStartTime!) >= _calibrationDuration) {
      setState(() {
        _isCalibrating = false;
      });
    }
  }

  Offset _mapRawEyeToTrackingCanvas(Offset rawEye, {required Size imageSize}) {
    const double canvasSize = 300.0;

    double nx;
    double ny;

    final calibratedRangeX = (_maxRawX - _minRawX).abs();
    final calibratedRangeY = (_maxRawY - _minRawY).abs();

    if (!_isCalibrating && calibratedRangeX > 1.0 && calibratedRangeY > 1.0) {
      nx = ((rawEye.dx - _minRawX) / calibratedRangeX).clamp(0.0, 1.0);
      ny = ((rawEye.dy - _minRawY) / calibratedRangeY).clamp(0.0, 1.0);
    } else {
      nx = (rawEye.dx / imageSize.width).clamp(0.0, 1.0);
      ny = (rawEye.dy / imageSize.height).clamp(0.0, 1.0);
    }

    // Front camera preview is mirrored on many devices, so invert X for intuitive mapping.
    if (_cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front) {
      nx = 1.0 - nx;
    }

    return Offset(nx * canvasSize, ny * canvasSize);
  }

  Offset _smoothOffset(Offset previous, Offset current, double alpha) {
    return Offset(
      previous.dx + (current.dx - previous.dx) * alpha,
      previous.dy + (current.dy - previous.dy) * alpha,
    );
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
        rotation: _inputImageRotationFromCamera(),
        format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      print('Error creating InputImage: $e');
      return null;
    }
  }

  InputImageRotation _inputImageRotationFromCamera() {
    if (_cameraController == null) return InputImageRotation.rotation0deg;

    final camera = _cameras[_selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    final deviceRotation = switch (_cameraController!.value.deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };

    final rotationCompensation =
        camera.lensDirection == CameraLensDirection.front
            ? (sensorOrientation + deviceRotation) % 360
            : (sensorOrientation - deviceRotation + 360) % 360;

    return InputImageRotationValue.fromRawValue(rotationCompensation) ??
        InputImageRotation.rotation0deg;
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
      _isCalibrating = true;
      _calibrationStartTime = DateTime.now();
      _minRawX = double.infinity;
      _maxRawX = double.negativeInfinity;
      _minRawY = double.infinity;
      _maxRawY = double.negativeInfinity;
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
      _isCalibrating = false;
      _calibrationStartTime = null;
      _minRawX = double.infinity;
      _maxRawX = double.negativeInfinity;
      _minRawY = double.infinity;
      _maxRawY = double.negativeInfinity;
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
      print('DEBUG: currentUser = $currentUser');
      if (currentUser != null) {
        print('DEBUG: Storing test result for user: ${currentUser.uid}');
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
        print('✅ Eye tracking test result stored: Accuracy $accuracy%');
      } else {
        print('❌ ERROR: currentUser is null - user not authenticated');
      }
    } catch (e) {
      print('❌ Error storing test result: $e');
      rethrow;
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
      _faceMeshDetector.close();
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
                  if (_isCalibrating)
                    Text(
                      "Calibrating eyes... ${(calibrationProgress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                    onPressed: () async {
                      await _storeTestResult();
                      if (mounted) {
                        Navigator.pop(context);
                      }
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