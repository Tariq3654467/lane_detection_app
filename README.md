# Lane Detection App

A Flutter application that performs real-time lane detection using computer vision techniques. The app uses the device's camera to detect lane markings on roads and provides lane departure warnings and steering suggestions.

## Features

- 🚗 **Real-time Lane Detection**: Detects lane markings using computer vision algorithms
- ⚠️ **Lane Departure Warning**: Alerts when the vehicle drifts or departs from the lane
- 🧭 **Steering Suggestions**: Provides real-time steering recommendations
- 📊 **Performance Metrics**: Displays FPS and processing time
- 🎨 **Visual Overlay**: Draws detected lanes directly on the camera preview
- 📱 **Cross-platform**: Works on Android, iOS, and other Flutter-supported platforms

## Screenshots

The app displays:
- Live camera preview with lane overlay
- Top bar showing FPS, processing time, and detection status
- Bottom panel with lane departure warnings and steering suggestions
- Visual indicators for lane detection status

## Requirements

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- A device with a camera (for testing)
- Camera permissions enabled

## Installation

1. **Clone the repository** (or navigate to the project directory):
   ```bash
   cd lane_detection_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Platform-Specific Setup

### Android

The app requires camera permissions. These are automatically requested when the app starts. Make sure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS

Add camera permission to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for lane detection</string>
```

## Project Structure

```
lib/
├── main.dart                    # Main app entry point and UI
├── camera_service.dart          # Camera initialization and management
├── lane_detection.dart          # Core lane detection algorithms
├── lane_departure_warning.dart  # Lane departure warning system
└── image_processor.dart         # Image processing utilities
```

### Key Components

- **LaneDetectionScreen**: Main screen that displays camera preview and overlays
- **CameraService**: Handles camera initialization, permissions, and image streaming
- **LaneDetection**: Implements Hough Transform and line detection algorithms
- **LaneDepartureWarningSystem**: Monitors vehicle position and provides warnings
- **LaneOverlayPainter**: Custom painter for drawing lane lines on camera preview
- **ImageProcessor**: Utilities for YUV to RGB conversion, grayscale, blur, and edge detection

## How It Works

1. **Image Capture**: The app continuously captures frames from the device camera
2. **Preprocessing**: Each frame is converted to grayscale, blurred, and processed with Canny edge detection
3. **ROI (Region of Interest)**: Focuses on the lower portion of the image where lanes are typically visible
4. **Line Detection**: Uses Hough Transform to detect straight lines in the edge-detected image
5. **Lane Separation**: Separates detected lines into left and right lanes based on slope and position
6. **Analysis**: Calculates lane curvature and vehicle offset from lane center
7. **Warning System**: Monitors vehicle position and triggers warnings when approaching or crossing lane boundaries
8. **Visualization**: Draws detected lanes and warnings on the camera preview

## Dependencies

- `camera: ^0.9.4+3` - Camera access and image streaming
- `image: ^4.1.7` - Image processing (grayscale, blur, edge detection)
- `permission_handler: ^10.0.0` - Camera permission management
- `path_provider: ^2.0.8` - File system paths
- `collection: ^1.18.0` - Advanced collection operations

## Usage

1. **Launch the app**: The camera will automatically initialize
2. **Point at a road**: Aim the camera at a road with visible lane markings
3. **View detection**: Detected lanes will appear as green lines on the preview
4. **Monitor warnings**: Watch for lane departure warnings in the bottom panel
5. **Follow suggestions**: Use steering suggestions to stay centered in the lane

## Performance

The app displays real-time performance metrics:
- **FPS**: Frames per second being processed
- **Processing Time**: Average time to process each frame
- **Detection Status**: Whether lanes are currently detected

## Limitations

- Works best with clear, visible lane markings
- Performance depends on device capabilities
- Requires good lighting conditions
- Designed for straight or slightly curved roads
- Not a replacement for professional driver assistance systems

## Future Improvements

- [ ] Machine learning-based lane detection for better accuracy
- [ ] Support for curved roads and complex scenarios
- [ ] Night mode with enhanced visibility
- [ ] Recording and playback functionality
- [ ] Multiple detection algorithms to choose from
- [ ] Calibration options for different vehicle types

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available for educational purposes.

## Disclaimer

⚠️ **Important**: This app is for educational and demonstration purposes only. It should NOT be used as a replacement for professional driver assistance systems or while driving. Always follow traffic laws and drive safely.

## Troubleshooting

### Camera not initializing
- Check that camera permissions are granted
- Ensure no other app is using the camera
- Restart the app

### Poor detection accuracy
- Ensure good lighting conditions
- Point camera at clear lane markings
- Hold device steady
- Try different angles

### Performance issues
- Close other apps to free up resources
- Lower camera resolution in `camera_service.dart`
- Reduce processing frequency

## Support

For issues, questions, or suggestions, please open an issue on the repository.

---

Made with ❤️ using Flutter

