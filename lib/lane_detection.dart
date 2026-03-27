import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'image_processor.dart';
import 'tflite_service.dart';

/// Represents a detected lane line
class LaneLine {
  final List<math.Point<int>> points;
  final double slope;
  final double intercept;
  final bool isLeft;

  LaneLine({
    required this.points,
    required this.slope,
    required this.intercept,
    required this.isLeft,
  });
}

/// Represents lane detection results
class LaneDetectionResult {
  final LaneLine? leftLane;
  final LaneLine? rightLane;
  final double? curvature;
  final double? vehicleOffset;
  final bool lanesDetected;
  final bool usedTFLite; // track which pipeline was used

  LaneDetectionResult({
    this.leftLane,
    this.rightLane,
    this.curvature,
    this.vehicleOffset,
    required this.lanesDetected,
    this.usedTFLite = false,
  });
}

/// Main lane detection class — tries TFLite model first, falls back to
/// classical Hough-transform pipeline if the model is not loaded or fails.
class LaneDetection {
  static const int minLineLength = 50;
  static const int maxLineGap = 10;
  static const double minSlope = 0.5;
  static const double maxSlope = 2.0;

  // ─────────────────────── Public entry point ──────────────────────

  /// Detect lanes from a CameraImage.
  static Future<LaneDetectionResult> detectLanes(CameraImage cameraImage) async {
    try {
      final image = _cameraImageToImage(cameraImage);
      if (image == null) return LaneDetectionResult(lanesDetected: false);

      // ── Try TFLite path ──────────────────────────────────────────
      final tflite = TFLiteService();
      if (tflite.isLoaded) {
        final result = _detectWithTFLite(image, tflite);
        if (result != null) return result;
      }

      // ── Algorithmic fallback ─────────────────────────────────────
      return _detectWithHough(image);
    } catch (e) {
      return LaneDetectionResult(lanesDetected: false);
    }
  }

  // ─────────────────────── TFLite pipeline ─────────────────────────

  static LaneDetectionResult? _detectWithTFLite(img.Image image, TFLiteService tflite) {
    try {
      final outputMask = tflite.runInference(image);
      if (outputMask == null) return null;

      // Output tensor shape [1, H, W, 1] or [1, H, W, C] — use first channel
      final maskH = tflite.modelInputHeight;
      final maskW = tflite.modelInputWidth;

      final laneLines = _parseMaskToLanes(outputMask, maskW, maskH, image.width, image.height);

      double? curvature;
      double? vehicleOffset;
      if (laneLines.leftLane != null && laneLines.rightLane != null) {
        curvature = _calculateCurvature(laneLines.leftLane!, laneLines.rightLane!, image.height);
        vehicleOffset = _calculateVehicleOffset(
          laneLines.leftLane!, laneLines.rightLane!, image.width, image.height);
      }

      return LaneDetectionResult(
        leftLane: laneLines.leftLane,
        rightLane: laneLines.rightLane,
        curvature: curvature,
        vehicleOffset: vehicleOffset,
        lanesDetected: laneLines.leftLane != null || laneLines.rightLane != null,
        usedTFLite: true,
      );
    } catch (e) {
      return null; // will trigger fallback
    }
  }

  /// Parse a flat segmentation mask into left/right LaneLines.
  ///
  /// Strategy: for each row in the bottom half, find the leftmost and
  /// rightmost activated pixel (value > 0.5) to the left/right of centre.
  static ({LaneLine? leftLane, LaneLine? rightLane}) _parseMaskToLanes(
    Float32List mask,
    int maskW,
    int maskH,
    int imgW,
    int imgH,
  ) {
    final scaleX = imgW / maskW;
    final scaleY = imgH / maskH;
    final centerX = maskW ~/ 2;

    final leftPoints = <math.Point<int>>[];
    final rightPoints = <math.Point<int>>[];

    // Only look at the bottom 60% of the mask (road region)
    final startRow = (maskH * 0.4).round();

    for (int row = startRow; row < maskH; row++) {
      int? leftMostX;
      int? rightMostX;

      for (int col = 0; col < maskW; col++) {
        // Support both [1,H,W,1] (stride = maskW) layouts
        final pixelValue = mask[row * maskW + col];
        if (pixelValue > 0.5) {
          if (col < centerX) {
            // Left side: track the rightmost activated pixel (lane boundary)
            if (leftMostX == null || col > leftMostX) leftMostX = col;
          } else {
            // Right side: track the leftmost activated pixel (lane boundary)
            if (rightMostX == null || col < rightMostX) rightMostX = col;
          }
        }
      }

      if (leftMostX != null) {
        leftPoints.add(math.Point(
          (leftMostX * scaleX).round(),
          (row * scaleY).round(),
        ));
      }
      if (rightMostX != null) {
        rightPoints.add(math.Point(
          (rightMostX * scaleX).round(),
          (row * scaleY).round(),
        ));
      }
    }

    LaneLine? leftLane;
    LaneLine? rightLane;

    if (leftPoints.length >= 5) {
      final fit = _fitLine(leftPoints);
      if (fit != null) {
        leftLane = LaneLine(
          points: leftPoints, slope: fit.slope, intercept: fit.intercept, isLeft: true);
      }
    }
    if (rightPoints.length >= 5) {
      final fit = _fitLine(rightPoints);
      if (fit != null) {
        rightLane = LaneLine(
          points: rightPoints, slope: fit.slope, intercept: fit.intercept, isLeft: false);
      }
    }

    return (leftLane: leftLane, rightLane: rightLane);
  }

  // ────────────────── Classical Hough pipeline (fallback) ──────────

  static LaneDetectionResult _detectWithHough(img.Image image) {
    // Downscale for faster processing (50%)
    final processedWidth = (image.width * 0.5).round();
    final processedHeight = (image.height * 0.5).round();
    final resizedImage =
        img.copyResize(image, width: processedWidth, height: processedHeight);

    final gray = ImageProcessor.grayscale(resizedImage);
    final blurred = ImageProcessor.gaussianBlur(gray, radius: 3);
    final edges = ImageProcessor.cannyEdgeDetection(
      blurred, lowThreshold: 50, highThreshold: 150);

    final roiMask = ImageProcessor.createROIMask(
      edges, topRatio: 0.5, bottomRatio: 0.95, leftRatio: 0.05, rightRatio: 0.95);
    final roiEdges = ImageProcessor.applyROI(edges, roiMask);

    final lines = _houghTransformOptimized(roiEdges);
    final laneLines = _separateLanes(lines, image.width, image.height);

    double? curvature;
    double? vehicleOffset;
    if (laneLines.leftLane != null && laneLines.rightLane != null) {
      curvature =
          _calculateCurvature(laneLines.leftLane!, laneLines.rightLane!, image.height);
      vehicleOffset = _calculateVehicleOffset(
          laneLines.leftLane!, laneLines.rightLane!, image.width, image.height);
    }

    return LaneDetectionResult(
      leftLane: laneLines.leftLane,
      rightLane: laneLines.rightLane,
      curvature: curvature,
      vehicleOffset: vehicleOffset,
      lanesDetected: laneLines.leftLane != null && laneLines.rightLane != null,
      usedTFLite: false,
    );
  }

  // ──────────────────── Shared helpers ─────────────────────────────

  /// Convert CameraImage (YUV420) to img.Image
  static img.Image? _cameraImageToImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return ImageProcessor.yuv420ToImage(
          cameraImage.planes[0].bytes,
          cameraImage.planes[1].bytes,
          cameraImage.planes[2].bytes,
          cameraImage.width,
          cameraImage.height,
          cameraImage.planes[0].bytesPerRow,
          cameraImage.planes[1].bytesPerRow,
          cameraImage.planes[2].bytesPerRow,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static ({math.Point<int> p1, math.Point<int> p2}) _createLine(
      math.Point<int> p1, math.Point<int> p2) {
    return (p1: p1, p2: p2);
  }

  static List<({math.Point<int> p1, math.Point<int> p2})>
      _houghTransformOptimized(img.Image edges) {
    final lines = <({math.Point<int> p1, math.Point<int> p2})>[];
    final width = edges.width;
    final height = edges.height;

    final maxRho = math.sqrt(width * width + height * height).round();
    const rhoStep = 2.0;
    final thetaStep = math.pi / 90.0;
    final rhoSize = ((2 * maxRho) / rhoStep).round();
    const thetaSize = 90;

    final accumulator =
        List.generate(rhoSize, (_) => List.filled(thetaSize, 0));

    const step = 2;
    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final pixel = edges.getPixel(x, y);
        if (img.getLuminance(pixel) > 128) {
          for (int thetaIndex = 0; thetaIndex < thetaSize; thetaIndex++) {
            final theta = thetaIndex * thetaStep;
            final rho = (x * math.cos(theta) + y * math.sin(theta));
            final rhoIndex = ((rho + maxRho) / rhoStep).round();
            if (rhoIndex >= 0 && rhoIndex < accumulator.length) {
              accumulator[rhoIndex][thetaIndex]++;
            }
          }
        }
      }
    }

    const threshold = 30;
    for (int rhoIndex = 0; rhoIndex < accumulator.length; rhoIndex++) {
      for (int thetaIndex = 0; thetaIndex < thetaSize; thetaIndex++) {
        if (accumulator[rhoIndex][thetaIndex] > threshold) {
          final rho = (rhoIndex * rhoStep) - maxRho;
          final theta = thetaIndex * thetaStep;
          final cosTheta = math.cos(theta);
          final sinTheta = math.sin(theta);

          if (sinTheta.abs() > 0.001) {
            final x1 = 0;
            final y1 = ((rho - x1 * cosTheta) / sinTheta).round();
            final x2 = width;
            final y2 = ((rho - x2 * cosTheta) / sinTheta).round();

            if (y1 >= 0 && y1 < height && y2 >= 0 && y2 < height) {
              lines.add(_createLine(math.Point(x1, y1), math.Point(x2, y2)));
            }
          }
        }
      }
    }
    return lines;
  }

  static ({LaneLine? leftLane, LaneLine? rightLane}) _separateLanes(
    List<({math.Point<int> p1, math.Point<int> p2})> lines,
    int imageWidth,
    int imageHeight,
  ) {
    final leftLines = <math.Point<int>>[];
    final rightLines = <math.Point<int>>[];
    final centerX = imageWidth ~/ 2;

    for (final line in lines) {
      final p1 = line.p1;
      final p2 = line.p2;
      if ((p2.x - p1.x).abs() < 1) continue;
      final slope = (p2.y - p1.y) / (p2.x - p1.x);
      if (slope.abs() < minSlope || slope.abs() > maxSlope) continue;

      final midX = (p1.x + p2.x) ~/ 2;
      if (slope < 0 && midX < centerX) {
        leftLines.addAll([p1, p2]);
      } else if (slope > 0 && midX > centerX) {
        rightLines.addAll([p1, p2]);
      }
    }

    LaneLine? leftLane;
    LaneLine? rightLane;

    if (leftLines.length >= 2) {
      final fitted = _fitLine(leftLines);
      if (fitted != null) {
        leftLane = LaneLine(
            points: leftLines,
            slope: fitted.slope,
            intercept: fitted.intercept,
            isLeft: true);
      }
    }
    if (rightLines.length >= 2) {
      final fitted = _fitLine(rightLines);
      if (fitted != null) {
        rightLane = LaneLine(
            points: rightLines,
            slope: fitted.slope,
            intercept: fitted.intercept,
            isLeft: false);
      }
    }

    return (leftLane: leftLane, rightLane: rightLane);
  }

  static ({double slope, double intercept})? _fitLine(
      List<math.Point<int>> points) {
    if (points.length < 2) return null;

    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = points.length;

    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumXX += point.x * point.x;
    }

    final denominator = n * sumXX - sumX * sumX;
    if (denominator.abs() < 0.001) return null;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;
    return (slope: slope, intercept: intercept);
  }

  static double _calculateCurvature(
      LaneLine leftLane, LaneLine rightLane, int imageHeight) {
    final y = imageHeight.toDouble();
    final leftX = (y - leftLane.intercept) / leftLane.slope;
    final rightX = (y - rightLane.intercept) / rightLane.slope;
    final laneWidth = (rightX - leftX).abs();
    final avgSlope = (leftLane.slope.abs() + rightLane.slope.abs()) / 2;
    return avgSlope / laneWidth * 1000;
  }

  static double _calculateVehicleOffset(
    LaneLine leftLane,
    LaneLine rightLane,
    int imageWidth,
    int imageHeight,
  ) {
    final y = imageHeight.toDouble();
    final leftX = (y - leftLane.intercept) / leftLane.slope;
    final rightX = (y - rightLane.intercept) / rightLane.slope;
    final laneCenterX = (leftX + rightX) / 2;
    final vehicleCenterX = imageWidth / 2;
    final offset = vehicleCenterX - laneCenterX;
    final laneWidthPixels = (rightX - leftX).abs();
    final metersPerPixel = 3.7 / laneWidthPixels;
    return offset * metersPerPixel;
  }

  // ─────────────────────────── Drawing ─────────────────────────────

  /// Draw detected lanes on image
  static img.Image drawLanes(img.Image image, LaneDetectionResult result) {
    final output =
        img.copyResize(image, width: image.width, height: image.height);

    if (result.leftLane != null) {
      _drawLaneLine(output, result.leftLane!, img.ColorRgb8(0, 255, 0));
    }
    if (result.rightLane != null) {
      _drawLaneLine(output, result.rightLane!, img.ColorRgb8(0, 255, 0));
    }
    if (result.leftLane != null && result.rightLane != null) {
      _drawLaneArea(output, result.leftLane!, result.rightLane!);
    }
    return output;
  }

  static void _drawLaneLine(img.Image image, LaneLine lane, img.Color color) {
    final height = image.height;
    final y1 = (height * 0.5).round();
    final y2 = height;
    final x1 = ((y1 - lane.intercept) / lane.slope).round();
    final x2 = ((y2 - lane.intercept) / lane.slope).round();

    img.drawLine(
      image,
      x1: x1.clamp(0, image.width),
      y1: y1.clamp(0, image.height),
      x2: x2.clamp(0, image.width),
      y2: y2.clamp(0, image.height),
      color: color,
      thickness: 5,
    );
  }

  static void _drawLaneArea(
      img.Image image, LaneLine leftLane, LaneLine rightLane) {
    final height = image.height;
    final y1 = (height * 0.5).round();
    final y2 = height;

    final leftX1 = ((y1 - leftLane.intercept) / leftLane.slope).round();
    final leftX2 = ((y2 - leftLane.intercept) / leftLane.slope).round();
    final rightX1 = ((y1 - rightLane.intercept) / rightLane.slope).round();
    final rightX2 = ((y2 - rightLane.intercept) / rightLane.slope).round();

    final leftX1C = leftX1.clamp(0, image.width);
    final leftX2C = leftX2.clamp(0, image.width);
    final rightX1C = rightX1.clamp(0, image.width);
    final rightX2C = rightX2.clamp(0, image.width);
    final y1C = y1.clamp(0, image.height);
    final y2C = y2.clamp(0, image.height);

    final fillColor = img.ColorRgba8(0, 255, 0, 100);
    final startY = y1C < y2C ? y1C : y2C;
    final endY = y1C > y2C ? y1C : y2C;

    for (int y = startY; y <= endY; y++) {
      final t = endY > startY ? (y - startY) / (endY - startY) : 0.0;
      final leftX = (leftX1C + (leftX2C - leftX1C) * t).round();
      final rightX = (rightX1C + (rightX2C - rightX1C) * t).round();
      final xStart = leftX < rightX ? leftX : rightX;
      final xEnd = leftX > rightX ? leftX : rightX;

      for (int x = xStart.clamp(0, image.width);
          x <= xEnd.clamp(0, image.width);
          x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, fillColor);
        }
      }
    }
  }
}
