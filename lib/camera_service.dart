import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  StreamSubscription<CameraImage>? _imageStreamSubscription;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<bool> requestPermissions() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> initialize() async {
    try {
      // Request camera permission
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Initialize camera controller with back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium, // Use medium instead of high for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (_controller == null || !_isInitialized) {
      throw Exception('Camera not initialized');
    }

    // Stop any existing stream first
    try {
      await _controller!.stopImageStream();
    } catch (e) {
      // Ignore errors if stream wasn't running
    }

    // Start image stream with error handling
    await _controller!.startImageStream((image) {
      try {
        onImage(image);
      } catch (e) {
        debugPrint('Error in image stream callback: $e');
      }
    });
  }

  Future<void> stopImageStream() async {
    await _controller?.stopImageStream();
    await _imageStreamSubscription?.cancel();
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
