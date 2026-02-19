import 'package:flutter/material.dart';
import 'camera_service.dart';
import 'lane_detection.dart';

void main() {
  runApp(LaneDetectionApp());
}

class LaneDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lane Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LaneDetectionScreen(),
    );
  }
}

class LaneDetectionScreen extends StatefulWidget {
  @override
  _LaneDetectionScreenState createState() => _LaneDetectionScreenState();
}

class _LaneDetectionScreenState extends State<LaneDetectionScreen> {
  final CameraService cameraService = CameraService();
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await cameraService.initialize();
    controller = cameraService.getController()!;
    cameraService.startImageStream((image) {
      processImage(image);
    });
    setState(() {});
  }

  void processImage(CameraImage image) {
    // Pass image to lane detection (You can use Canny edge detection here or CNN model)
    LaneDetection.detectLane(image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lane Detection'),
      ),
      body: controller.value.isInitialized
          ? CameraPreview(controller)
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    cameraService.dispose();
    super.dispose();
  }
}
