import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Image processing utilities for lane detection
class ImageProcessor {
  /// Convert YUV420 format (from CameraImage) to RGB Image
  static img.Image? yuv420ToImage(
    Uint8List yPlane,
    Uint8List uPlane,
    Uint8List vPlane,
    int width,
    int height,
    int yRowStride,
    int uRowStride,
    int vRowStride,
  ) {
    try {
      final image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = (y * yRowStride) + x;
          final uvIndex = ((y ~/ 2) * uRowStride) + (x ~/ 2);

          final yValue = yPlane[yIndex];
          final uValue = uPlane[uvIndex];
          final vValue = vPlane[uvIndex];

          // Convert YUV to RGB
          final r = _yuvToR(yValue, uValue, vValue);
          final g = _yuvToG(yValue, uValue, vValue);
          final b = _yuvToB(yValue, uValue, vValue);

          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }

      return image;
    } catch (e) {
      return null;
    }
  }

  static int _yuvToR(int y, int u, int v) {
    final r = (y + 1.402 * (v - 128)).round();
    return r.clamp(0, 255);
  }

  static int _yuvToG(int y, int u, int v) {
    final g = (y - 0.344 * (u - 128) - 0.714 * (v - 128)).round();
    return g.clamp(0, 255);
  }

  static int _yuvToB(int y, int u, int v) {
    final b = (y + 1.772 * (u - 128)).round();
    return b.clamp(0, 255);
  }

  /// Convert image to grayscale
  static img.Image grayscale(img.Image image) {
    return img.grayscale(image);
  }

  /// Apply Gaussian blur
  static img.Image gaussianBlur(img.Image image, {int radius = 5}) {
    return img.gaussianBlur(image, radius: radius);
  }

  /// Apply Canny edge detection
  static img.Image cannyEdgeDetection(
    img.Image image, {
    double lowThreshold = 50,
    double highThreshold = 150,
  }) {
    // Convert to grayscale if needed
    img.Image gray = image.numChannels == 1 ? image : grayscale(image);

    // Apply Gaussian blur
    gray = gaussianBlur(gray, radius: 5);

    // Sobel edge detection (simplified Canny)
    final width = gray.width;
    final height = gray.height;
    final edges = img.Image(width: width, height: height);

    // Sobel kernels
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]
    ];
    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1]
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        int gx = 0, gy = 0;

        for (int i = -1; i <= 1; i++) {
          for (int j = -1; j <= 1; j++) {
            final pixel = gray.getPixel(x + j, y + i);
            final intensity = img.getLuminance(pixel).round();

            gx += intensity * sobelX[i + 1][j + 1];
            gy += intensity * sobelY[i + 1][j + 1];
          }
        }

        final magnitude = math.sqrt(gx * gx + gy * gy).round();
        final edgeValue = magnitude > highThreshold
            ? 255
            : (magnitude > lowThreshold ? 128 : 0);

        edges.setPixel(x, y, img.ColorRgb8(edgeValue, edgeValue, edgeValue));
      }
    }

    return edges;
  }

  /// Create a mask for Region of Interest (ROI)
  static img.Image createROIMask(img.Image image, {
    double topRatio = 0.5,
    double bottomRatio = 0.9,
    double leftRatio = 0.1,
    double rightRatio = 0.9,
  }) {
    final mask = img.Image(width: image.width, height: image.height);
    final topY = (image.height * topRatio).round();
    final bottomY = (image.height * bottomRatio).round();
    final leftX = (image.width * leftRatio).round();
    final rightX = (image.width * rightRatio).round();

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (y >= topY && y <= bottomY && x >= leftX && x <= rightX) {
          mask.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        } else {
          mask.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }

    return mask;
  }

  /// Apply ROI mask to image
  static img.Image applyROI(img.Image image, img.Image mask) {
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final maskPixel = mask.getPixel(x, y);
        if (img.getLuminance(maskPixel) > 128) {
          result.setPixel(x, y, image.getPixel(x, y));
        } else {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }
    return result;
  }
}

