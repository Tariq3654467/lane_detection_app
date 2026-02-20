import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';
import 'lane_detection.dart';
import 'lane_departure_warning.dart';

void main() {
  runApp(const LaneDetectionApp());
}

class LaneDetectionApp extends StatelessWidget {
  const LaneDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lane Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LaneDetectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LaneDetectionScreen extends StatefulWidget {
  const LaneDetectionScreen({super.key});

  @override
  State<LaneDetectionScreen> createState() => _LaneDetectionScreenState();
}

class _LaneDetectionScreenState extends State<LaneDetectionScreen> {
  final CameraService _cameraService = CameraService();
  CameraController? _controller;
  bool _isProcessing = false;
  LaneDetectionResult? _lastResult;
  LaneDepartureStatus _departureStatus = LaneDepartureStatus.normal;
  SteeringSuggestion _steeringSuggestion = SteeringSuggestion.unknown;

  // Performance metrics
  int _frameCount = 0;
  DateTime? _lastFpsUpdate;
  double _currentFps = 0.0;
  double _avgProcessingTime = 0.0;
  final List<double> _processingTimes = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      setState(() {
        _controller = _cameraService.controller;
      });

      if (_controller != null) {
        await _cameraService.startImageStream(_processFrame);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;
    final startTime = DateTime.now();

    try {
      final result = await LaneDetection.detectLanes(image);
      final processingTime = DateTime.now().difference(startTime).inMilliseconds.toDouble();

      if (mounted) {
        setState(() {
          _lastResult = result;
          _departureStatus = LaneDepartureWarningSystem.checkDeparture(result);
          _steeringSuggestion = LaneDepartureWarningSystem.getSteeringSuggestion(result);

          // Update performance metrics
          _frameCount++;
          _processingTimes.add(processingTime);
          if (_processingTimes.length > 30) {
            _processingTimes.removeAt(0);
          }
          _avgProcessingTime = _processingTimes.reduce((a, b) => a + b) / _processingTimes.length;

          // Calculate FPS
          final now = DateTime.now();
          if (_lastFpsUpdate == null) {
            _lastFpsUpdate = now;
          } else {
            final elapsed = now.difference(_lastFpsUpdate!).inSeconds;
            if (elapsed >= 1) {
              _currentFps = _frameCount / elapsed;
              _frameCount = 0;
              _lastFpsUpdate = now;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing camera...'),
                ],
              ),
            )
          : Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),

                // Lane overlay
                if (_lastResult != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LaneOverlayPainter(_lastResult!),
                    ),
                  ),

                // UI Overlay
                Positioned.fill(
                  child: Column(
                    children: [
                      // Top info bar
                      _buildTopInfoBar(),

                      const Spacer(),

                      // Bottom info panel
                      _buildBottomInfoPanel(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // FPS indicator
            _buildMetricCard(
              'FPS',
              _currentFps.toStringAsFixed(1),
              Colors.green,
            ),
            const SizedBox(width: 8),
            // Processing time
            _buildMetricCard(
              'Time',
              '${_avgProcessingTime.toStringAsFixed(0)}ms',
              Colors.blue,
            ),
            const SizedBox(width: 8),
            // Detection status
            _buildMetricCard(
              'Status',
              _lastResult?.lanesDetected == true ? 'ON' : 'OFF',
              _lastResult?.lanesDetected == true ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w300,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lane departure warning
            if (_departureStatus != LaneDepartureStatus.normal)
              _buildWarningCard(_departureStatus),

            const SizedBox(height: 12),

            // Steering suggestion
            if (_steeringSuggestion != SteeringSuggestion.unknown)
              _buildSteeringCard(_steeringSuggestion),

            const SizedBox(height: 12),

            // Lane information
            if (_lastResult != null && _lastResult!.lanesDetected)
              _buildLaneInfoCard(_lastResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard(LaneDepartureStatus status) {
    Color color;
    String message;
    IconData icon;

    switch (status) {
      case LaneDepartureStatus.warningLeft:
        color = Colors.orange;
        message = 'Warning: Drifting Left';
        icon = Icons.arrow_back;
        break;
      case LaneDepartureStatus.warningRight:
        color = Colors.orange;
        message = 'Warning: Drifting Right';
        icon = Icons.arrow_forward;
        break;
      case LaneDepartureStatus.departureLeft:
        color = Colors.red;
        message = 'ALERT: Lane Departure Left!';
        icon = Icons.warning;
        break;
      case LaneDepartureStatus.departureRight:
        color = Colors.red;
        message = 'ALERT: Lane Departure Right!';
        icon = Icons.warning;
        break;
      default:
        color = Colors.green;
        message = 'Normal';
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteeringCard(SteeringSuggestion suggestion) {
    String message;
    IconData icon;
    Color color;

    switch (suggestion) {
      case SteeringSuggestion.steerLeft:
        message = 'Steer Left';
        icon = Icons.arrow_back;
        color = Colors.blue;
        break;
      case SteeringSuggestion.steerRight:
        message = 'Steer Right';
        icon = Icons.arrow_forward;
        color = Colors.blue;
        break;
      case SteeringSuggestion.slightLeft:
        message = 'Slight Left';
        icon = Icons.arrow_back;
        color = Colors.blue.shade300;
        break;
      case SteeringSuggestion.slightRight:
        message = 'Slight Right';
        icon = Icons.arrow_forward;
        color = Colors.blue.shade300;
        break;
      case SteeringSuggestion.straight:
        message = 'Keep Straight';
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      default:
        message = 'No Suggestion';
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaneInfoCard(LaneDetectionResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Text(
            'Lanes Detected: ${result.lanesDetected ? 'Yes' : 'No'}',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.stopImageStream();
    _cameraService.dispose();
    super.dispose();
  }
}

/// Custom painter to draw lane lines on camera preview
class LaneOverlayPainter extends CustomPainter {
  final LaneDetectionResult result;

  LaneOverlayPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.lanesDetected) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Draw left lane
    if (result.leftLane != null) {
      _drawLaneLine(canvas, size, result.leftLane!, paint);
    }

    // Draw right lane
    if (result.rightLane != null) {
      _drawLaneLine(canvas, size, result.rightLane!, paint);
    }

    // Draw lane area if both lanes detected
    if (result.leftLane != null && result.rightLane != null) {
      final areaPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      _drawLaneArea(canvas, size, result.leftLane!, result.rightLane!, areaPaint);
    }
  }

  void _drawLaneLine(Canvas canvas, Size size, LaneLine lane, Paint paint) {
    final height = size.height;
    final y1 = height * 0.5;
    final y2 = height;

    final x1 = (y1 - lane.intercept) / lane.slope;
    final x2 = (y2 - lane.intercept) / lane.slope;

    // Clamp coordinates to canvas bounds
    final startX = x1.clamp(0.0, size.width);
    final startY = y1.clamp(0.0, size.height);
    final endX = x2.clamp(0.0, size.width);
    final endY = y2.clamp(0.0, size.height);

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
  }

  void _drawLaneArea(
    Canvas canvas,
    Size size,
    LaneLine leftLane,
    LaneLine rightLane,
    Paint paint,
  ) {
    final height = size.height;
    final y1 = height * 0.5;
    final y2 = height;

    final leftX1 = ((y1 - leftLane.intercept) / leftLane.slope).clamp(0.0, size.width);
    final leftX2 = ((y2 - leftLane.intercept) / leftLane.slope).clamp(0.0, size.width);
    final rightX1 = ((y1 - rightLane.intercept) / rightLane.slope).clamp(0.0, size.width);
    final rightX2 = ((y2 - rightLane.intercept) / rightLane.slope).clamp(0.0, size.width);

    final path = Path()
      ..moveTo(leftX1, y1)
      ..lineTo(leftX2, y2)
      ..lineTo(rightX2, y2)
      ..lineTo(rightX1, y1)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LaneOverlayPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
