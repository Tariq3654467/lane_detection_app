import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'image_processor.dart';

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

  LaneDetectionResult({
    this.leftLane,
    this.rightLane,
    this.curvature,
    this.vehicleOffset,
    required this.lanesDetected,
  });
}

/// Main lane detection class
class LaneDetection {
  static const int minLineLength = 50;
  static const int maxLineGap = 10;
  static const double minSlope = 0.5;
  static const double maxSlope = 2.0;

  /// Detect lanes from camera image
  static Future<LaneDetectionResult> detectLanes(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to Image
      final image = _cameraImageToImage(cameraImage);
      if (image == null) {
        return LaneDetectionResult(lanesDetected: false);
      }

      // Preprocessing
      final gray = ImageProcessor.grayscale(image);
      final blurred = ImageProcessor.gaussianBlur(gray, radius: 5);
      final edges = ImageProcessor.cannyEdgeDetection(
        blurred,
        lowThreshold: 50,
        highThreshold: 150,
      );

      // Apply ROI
      final roiMask = ImageProcessor.createROIMask(
        edges,
        topRatio: 0.5,
        bottomRatio: 0.95,
        leftRatio: 0.05,
        rightRatio: 0.95,
      );
      final roiEdges = ImageProcessor.applyROI(edges, roiMask);

      // Detect lines using Hough Transform
      final lines = _houghTransform(roiEdges);

      // Separate left and right lanes
      final laneLines = _separateLanes(lines, image.width, image.height);

      // Calculate curvature and vehicle offset
      double? curvature;
      double? vehicleOffset;

      if (laneLines.leftLane != null && laneLines.rightLane != null) {
        curvature = _calculateCurvature(laneLines.leftLane!, laneLines.rightLane!, image.height);
        vehicleOffset = _calculateVehicleOffset(
          laneLines.leftLane!,
          laneLines.rightLane!,
          image.width,
          image.height,
        );
      }

      return LaneDetectionResult(
        leftLane: laneLines.leftLane,
        rightLane: laneLines.rightLane,
        curvature: curvature,
        vehicleOffset: vehicleOffset,
        lanesDetected: laneLines.leftLane != null && laneLines.rightLane != null,
      );
    } catch (e) {
      return LaneDetectionResult(lanesDetected: false);
    }
  }

  /// Convert CameraImage to Image object
  static img.Image? _cameraImageToImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final yPlane = cameraImage.planes[0].bytes;
        final uPlane = cameraImage.planes[1].bytes;
        final vPlane = cameraImage.planes[2].bytes;

        return ImageProcessor.yuv420ToImage(
          yPlane,
          uPlane,
          vPlane,
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

  /// Represents a line with two endpoints
  static ({math.Point<int> p1, math.Point<int> p2}) _createLine(math.Point<int> p1, math.Point<int> p2) {
    return (p1: p1, p2: p2);
  }

  /// Hough Transform for line detection
  static List<({math.Point<int> p1, math.Point<int> p2})> _houghTransform(img.Image edges) {
    final lines = <({math.Point<int> p1, math.Point<int> p2})>[];
    final width = edges.width;
    final height = edges.height;

    // Accumulator array for Hough space
    final maxRho = math.sqrt(width * width + height * height).round();
    final rhoStep = 1.0;
    final thetaStep = math.pi / 180.0;
    final accumulator = List.generate(
      (2 * maxRho).round(),
      (_) => List.filled(180, 0),
    );

    // Vote in accumulator
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = edges.getPixel(x, y);
        if (img.getLuminance(pixel) > 128) {
          for (int thetaIndex = 0; thetaIndex < 180; thetaIndex++) {
            final theta = thetaIndex * thetaStep;
            final rho = (x * math.cos(theta) + y * math.sin(theta)).round();
            final rhoIndex = rho + maxRho;
            if (rhoIndex >= 0 && rhoIndex < accumulator.length) {
              accumulator[rhoIndex][thetaIndex]++;
            }
          }
        }
      }
    }

    // Find peaks in accumulator
    final threshold = 50;
    for (int rhoIndex = 0; rhoIndex < accumulator.length; rhoIndex++) {
      for (int thetaIndex = 0; thetaIndex < 180; thetaIndex++) {
        if (accumulator[rhoIndex][thetaIndex] > threshold) {
          final rho = rhoIndex - maxRho;
          final theta = thetaIndex * thetaStep;

          // Convert to line endpoints
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

  /// Separate detected lines into left and right lanes
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

      // Calculate slope
      if ((p2.x - p1.x).abs() < 1) continue;
      final slope = (p2.y - p1.y) / (p2.x - p1.x);

      if (slope.abs() < minSlope || slope.abs() > maxSlope) continue;

      // Determine if left or right lane
      final midX = (p1.x + p2.x) ~/ 2;
      if (slope < 0 && midX < centerX) {
        // Left lane (negative slope, left side)
        leftLines.addAll([p1, p2]);
      } else if (slope > 0 && midX > centerX) {
        // Right lane (positive slope, right side)
        rightLines.addAll([p1, p2]);
      }
    }

    // Fit lines to points
    LaneLine? leftLane;
    LaneLine? rightLane;

    if (leftLines.length >= 2) {
      final fitted = _fitLine(leftLines);
      if (fitted != null) {
        leftLane = LaneLine(
          points: leftLines,
          slope: fitted.slope,
          intercept: fitted.intercept,
          isLeft: true,
        );
      }
    }

    if (rightLines.length >= 2) {
      final fitted = _fitLine(rightLines);
      if (fitted != null) {
        rightLane = LaneLine(
          points: rightLines,
          slope: fitted.slope,
          intercept: fitted.intercept,
          isLeft: false,
        );
      }
    }

    return (leftLane: leftLane, rightLane: rightLane);
  }

  /// Fit a line to points using least squares
  static ({double slope, double intercept})? _fitLine(List<math.Point<int>> points) {
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

  /// Calculate lane curvature (simplified)
  static double _calculateCurvature(LaneLine leftLane, LaneLine rightLane, int imageHeight) {
    // Calculate curvature at bottom of image
    final y = imageHeight.toDouble();
    final leftX = (y - leftLane.intercept) / leftLane.slope;
    final rightX = (y - rightLane.intercept) / rightLane.slope;

    // Lane width
    final laneWidth = (rightX - leftX).abs();

    // Simplified curvature calculation
    final avgSlope = (leftLane.slope.abs() + rightLane.slope.abs()) / 2;
    final curvature = avgSlope / laneWidth * 1000; // Scale factor

    return curvature;
  }

  /// Calculate vehicle offset from lane center
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

    // Offset in pixels (positive = right, negative = left)
    final offset = vehicleCenterX - laneCenterX;

    // Convert to meters (assuming ~3.7m lane width, approximate conversion)
    final laneWidthPixels = (rightX - leftX).abs();
    final metersPerPixel = 3.7 / laneWidthPixels;
    final offsetMeters = offset * metersPerPixel;

    return offsetMeters;
  }

  /// Draw detected lanes on image
  static img.Image drawLanes(img.Image image, LaneDetectionResult result) {
    final output = img.copyResize(image, width: image.width, height: image.height);

    if (result.leftLane != null) {
      _drawLaneLine(output, result.leftLane!, img.ColorRgb8(0, 255, 0));
    }

    if (result.rightLane != null) {
      _drawLaneLine(output, result.rightLane!, img.ColorRgb8(0, 255, 0));
    }

    // Draw lane area if both lanes detected
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

  static void _drawLaneArea(img.Image image, LaneLine leftLane, LaneLine rightLane) {
    final height = image.height;
    final y1 = (height * 0.5).round();
    final y2 = height;

    final leftX1 = ((y1 - leftLane.intercept) / leftLane.slope).round();
    final leftX2 = ((y2 - leftLane.intercept) / leftLane.slope).round();
    final rightX1 = ((y1 - rightLane.intercept) / rightLane.slope).round();
    final rightX2 = ((y2 - rightLane.intercept) / rightLane.slope).round();

    final points = [
      math.Point(leftX1.clamp(0, image.width), y1.clamp(0, image.height)),
      math.Point(leftX2.clamp(0, image.width), y2.clamp(0, image.height)),
      math.Point(rightX2.clamp(0, image.width), y2.clamp(0, image.height)),
      math.Point(rightX1.clamp(0, image.width), y1.clamp(0, image.height)),
    ];

    // Draw filled polygon manually
    final polygonPoints = points.map((p) => img.Point(p.x, p.y)).toList();
    final fillColor = img.ColorRgba8(0, 255, 0, 100);
    
    // Use fillPolygon with correct signature
    img.fillPolygon(
      image,
      polygonPoints,
      color: fillColor,
    );
  }
}
