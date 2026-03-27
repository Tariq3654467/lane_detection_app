import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Singleton service that loads and runs the lane detection TFLite model.
class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _interpreter;
  List<int>? _inputShape;   // e.g. [1, H, W, 3]
  List<int>? _outputShape;  // e.g. [1, H, W, 1] or [1, C, H, W]
  TensorType? _inputType;
  TensorType? _outputType;

  bool get isLoaded => _interpreter != null;

  /// Input image height expected by the model (default 256 until loaded).
  int get modelInputHeight => (_inputShape != null && _inputShape!.length >= 3) ? _inputShape![1] : 256;

  /// Input image width expected by the model (default 256 until loaded).
  int get modelInputWidth => (_inputShape != null && _inputShape!.length >= 3) ? _inputShape![2] : 256;

  // ───────────────────────────── Load ──────────────────────────────

  /// Load the model from assets. Call once at app startup.
  Future<bool> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assests/lane_detection.tflite',
        options: interpreterOptions,
      );

      // Read tensor metadata
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      _inputShape = inputTensor.shape;
      _outputShape = outputTensor.shape;
      _inputType = inputTensor.type;
      _outputType = outputTensor.type;

      debugPrint('[TFLite] Model loaded successfully');
      debugPrint('[TFLite] Input  shape: $_inputShape  type: $_inputType');
      debugPrint('[TFLite] Output shape: $_outputShape type: $_outputType');
      return true;
    } catch (e) {
      debugPrint('[TFLite] Failed to load model: $e');
      _interpreter = null;
      return false;
    }
  }

  // ──────────────────────────── Inference ──────────────────────────

  /// Run inference on a resized RGB image.
  ///
  /// [rgbImage] — an `img.Image` already decoded to RGB.
  /// Returns a flat [Float32List] of the output tensor, or null on error.
  Float32List? runInference(img.Image rgbImage) {
    if (!isLoaded) return null;

    try {
      // Resize to model's expected input dimensions
      final resized = img.copyResize(
        rgbImage,
        width: modelInputWidth,
        height: modelInputHeight,
        interpolation: img.Interpolation.linear,
      );

      // Build input tensor [1, H, W, 3]
      final inputBuffer = Float32List(1 * modelInputHeight * modelInputWidth * 3);
      int idx = 0;
      for (int y = 0; y < modelInputHeight; y++) {
        for (int x = 0; x < modelInputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          inputBuffer[idx++] = pixel.r / 255.0;
          inputBuffer[idx++] = pixel.g / 255.0;
          inputBuffer[idx++] = pixel.b / 255.0;
        }
      }

      // Reshape to [1, H, W, 3]
      final input = inputBuffer.reshape([1, modelInputHeight, modelInputWidth, 3]);

      // Allocate output buffer
      final outputSize = _outputShape!.reduce((a, b) => a * b);
      final outputBuffer = Float32List(outputSize);
      final output = outputBuffer.reshape(_outputShape!);

      _interpreter!.run(input, output);
      return outputBuffer;
    } catch (e) {
      debugPrint('[TFLite] Inference error: $e');
      return null;
    }
  }

  // ──────────────────────────── Dispose ────────────────────────────

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
