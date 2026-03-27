import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'camera_service.dart';
import 'lane_detection.dart';
import 'lane_departure_warning.dart';
import 'dashboard_data.dart';
import 'dashboard_screen.dart';
import 'tflite_service.dart';

void main() {
  runApp(const LaneDetectionApp());
}

class LaneDetectionApp extends StatelessWidget {
  const LaneDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lane Detection',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: const Color(0xFF10B981),
        tertiary: const Color(0xFFF59E0B),
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.grey.shade900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _loadingText = 'Loading AI Model...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _loadModelAndNavigate();
  }

  Future<void> _loadModelAndNavigate() async {
    // Load TFLite model while splash is visible
    final loaded = await TFLiteService().loadModel();
    if (mounted) {
      setState(() {
        _loadingText = loaded ? '✓ AI Model Ready' : 'Classic Mode (no model)';
      });
    }
    // Brief pause so user can read the status
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                    const Color(0xFF4C1D95),
                  ]
                : [
                    const Color(0xFF4F46E5),
                    const Color(0xFF7C3AED),
                    const Color(0xFFEC4899),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Icon Container with glow effect
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // App Title with gradient text effect
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                    ).createShader(bounds),
                    child: Text(
                      'Lane Detection',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time lane monitoring',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Animated loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late DashboardData _dashboardData;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardData(sessionStartTime: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentIndex == 0
            ? DashboardScreen(
                key: const ValueKey('dashboard'),
                data: _dashboardData,
              )
            : LaneDetectionScreen(
                key: const ValueKey('camera'),
                dashboardData: _dashboardData,
                onDataUpdate: () => setState(() {}),
                onBack: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.black.withOpacity(0.8) 
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.dashboard_outlined,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    selectedIcon: Icon(
                      Icons.dashboard_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    selectedIcon: Icon(
                      Icons.camera_alt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: 'Camera',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LaneDetectionScreen extends StatefulWidget {
  final DashboardData dashboardData;
  final VoidCallback onDataUpdate;
  final VoidCallback? onBack;

  const LaneDetectionScreen({
    super.key,
    required this.dashboardData,
    required this.onDataUpdate,
    this.onBack,
  });

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

  int _frameCount = 0;
  DateTime? _lastFpsUpdate;
  double _currentFps = 0.0;
  double _avgProcessingTime = 0.0;
  final List<double> _processingTimes = [];
  int _frameSkipCount = 0;
  static const int _frameSkipInterval = 5;
  DateTime? _lastProcessTime;
  static const int _minProcessingIntervalMs = 200;

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
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    _frameSkipCount++;
    if (_frameSkipCount < _frameSkipInterval) {
      return;
    }
    _frameSkipCount = 0;

    final now = DateTime.now();
    if (_lastProcessTime != null) {
      final timeSinceLastProcess = now.difference(_lastProcessTime!).inMilliseconds;
      if (timeSinceLastProcess < _minProcessingIntervalMs) {
        return;
      }
    }

    if (_isProcessing || !mounted) return;

    _isProcessing = true;
    _lastProcessTime = now;
    final startTime = DateTime.now();

    try {
      final result = await Future(() => LaneDetection.detectLanes(image)).timeout(
        const Duration(seconds: 1),
        onTimeout: () => LaneDetectionResult(lanesDetected: false),
      );

      final processingTime = DateTime.now().difference(startTime).inMilliseconds.toDouble();

      if (!mounted) return;

      final departureStatus = LaneDepartureWarningSystem.checkDeparture(result);
      final steeringSuggestion = LaneDepartureWarningSystem.getSteeringSuggestion(result);

      _frameCount++;
      _processingTimes.add(processingTime);
      if (_processingTimes.length > 30) {
        _processingTimes.removeAt(0);
      }
      _avgProcessingTime = _processingTimes.reduce((a, b) => a + b) / _processingTimes.length;

      final fpsNow = DateTime.now();
      if (_lastFpsUpdate == null) {
        _lastFpsUpdate = fpsNow;
      } else {
        final elapsed = fpsNow.difference(_lastFpsUpdate!).inSeconds;
        if (elapsed >= 1) {
          _currentFps = _frameCount / elapsed;
          _frameCount = 0;
          _lastFpsUpdate = fpsNow;
        }
      }

      widget.dashboardData.updateWithFrame(
        lanesDetected: result.lanesDetected,
        processingTime: processingTime,
        fps: _currentFps > 0 ? _currentFps : 0.0,
        result: result,
        departureStatus: departureStatus,
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
          _departureStatus = departureStatus;
          _steeringSuggestion = steeringSuggestion;
        });
        widget.onDataUpdate();
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing frame: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: _controller == null || !_controller!.value.isInitialized
          ? _buildLoadingState()
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

                // Glassmorphism UI Overlay
                Positioned.fill(
                  child: _buildGlassOverlay(isDark, colorScheme),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Camera...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassOverlay(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        // Top glass bar with metrics
        _buildTopGlassBar(isDark),
        
        const Spacer(),
        
        // Bottom glass panel
        _buildBottomGlassPanel(isDark, colorScheme),
      ],
    );
  }

  Widget _buildTopGlassBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.6) 
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.white.withOpacity(0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _buildGlassButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: widget.onBack,
                    isDark: isDark,
                  ),
                  
                  // Metrics Row
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGlassMetric('FPS', _currentFps.toStringAsFixed(1), Colors.green, isDark),
                        _buildGlassMetric('Time', '${_avgProcessingTime.toStringAsFixed(0)}ms', Colors.blue, isDark),
                        _buildGlassMetric(
                          'Status',
                          _lastResult?.lanesDetected == true ? 'ON' : 'OFF',
                          _lastResult?.lanesDetected == true ? Colors.green : Colors.red,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.1) 
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildGlassMetric(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildBottomGlassPanel(bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ]
                    : [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.white.withOpacity(0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lane departure warning
                  if (_departureStatus != LaneDepartureStatus.normal)
                    _buildGlassWarningCard(_departureStatus),

                  if (_departureStatus != LaneDepartureStatus.normal)
                    const SizedBox(height: 12),

                  // Steering suggestion
                  if (_steeringSuggestion != SteeringSuggestion.unknown)
                    _buildGlassSteeringCard(_steeringSuggestion),

                  if (_steeringSuggestion != SteeringSuggestion.unknown)
                    const SizedBox(height: 12),

                  // Lane information
                  if (_lastResult != null && _lastResult!.lanesDetected)
                    _buildGlassLaneInfoCard(_lastResult!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassWarningCard(LaneDepartureStatus status) {
    Color color;
    String message;
    IconData icon;

    switch (status) {
      case LaneDepartureStatus.warningLeft:
        color = Colors.orange;
        message = '⚠️ Warning: Drifting Left';
        icon = Icons.arrow_back;
        break;
      case LaneDepartureStatus.warningRight:
        color = Colors.orange;
        message = '⚠️ Warning: Drifting Right';
        icon = Icons.arrow_forward;
        break;
      case LaneDepartureStatus.departureLeft:
        color = Colors.red;
        message = '🚨 ALERT: Lane Departure Left!';
        icon = Icons.warning_rounded;
        break;
      case LaneDepartureStatus.departureRight:
        color = Colors.red;
        message = '🚨 ALERT: Lane Departure Right!';
        icon = Icons.warning_rounded;
        break;
      default:
        color = Colors.green;
        message = '✓ Normal';
        icon = Icons.check_circle;
    }

    return _buildInfoCard(
      icon: icon,
      message: message,
      color: color,
      borderColor: color.withOpacity(0.6),
      backgroundColor: color.withOpacity(0.15),
    );
  }

  Widget _buildGlassSteeringCard(SteeringSuggestion suggestion) {
    String message;
    IconData icon;
    Color color;

    switch (suggestion) {
      case SteeringSuggestion.steerLeft:
        message = '⬅️ Steer Left';
        icon = Icons.arrow_back;
        color = Colors.blue;
        break;
      case SteeringSuggestion.steerRight:
        message = '➡️ Steer Right';
        icon = Icons.arrow_forward;
        color = Colors.blue;
        break;
      case SteeringSuggestion.slightLeft:
        message = '↙️ Slight Left';
        icon = Icons.turn_left;
        color = Colors.lightBlue;
        break;
      case SteeringSuggestion.slightRight:
        message = '↗️ Slight Right';
        icon = Icons.turn_right;
        color = Colors.lightBlue;
        break;
      case SteeringSuggestion.straight:
        message = '⬆️ Keep Straight';
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      default:
        message = 'No Suggestion';
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return _buildInfoCard(
      icon: icon,
      message: message,
      color: color,
      borderColor: color.withOpacity(0.6),
      backgroundColor: color.withOpacity(0.15),
    );
  }

  Widget _buildGlassLaneInfoCard(LaneDetectionResult result) {
    return _buildInfoCard(
      icon: Icons.check_circle,
      message: '✓ Lanes Detected: Yes',
      color: Colors.green,
      borderColor: Colors.green.withOpacity(0.6),
      backgroundColor: Colors.green.withOpacity(0.15),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String message,
    required Color color,
    required Color borderColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isProcessing = false;
    _cameraService.stopImageStream().catchError((e) {
      debugPrint('Error stopping image stream: $e');
    });
    _cameraService.dispose().catchError((e) {
      debugPrint('Error disposing camera service: $e');
    });
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

    // Draw left lane
    if (result.leftLane != null) {
      _drawLaneLine(canvas, size, result.leftLane!, Colors.cyan);
    }

    // Draw right lane
    if (result.rightLane != null) {
      _drawLaneLine(canvas, size, result.rightLane!, Colors.cyan);
    }

    // Draw lane area if both lanes detected
    if (result.leftLane != null && result.rightLane != null) {
      _drawLaneArea(canvas, size, result.leftLane!, result.rightLane!);
    }
  }

  void _drawLaneLine(Canvas canvas, Size size, LaneLine lane, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final height = size.height;
    final y1 = height * 0.5;
    final y2 = height;

    final x1 = (y1 - lane.intercept) / lane.slope;
    final x2 = (y2 - lane.intercept) / lane.slope;

    final startX = x1.clamp(0.0, size.width);
    final startY = y1.clamp(0.0, size.height);
    final endX = x2.clamp(0.0, size.width);
    final endY = y2.clamp(0.0, size.height);

    // Draw glow effect first
    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      glowPaint,
    );

    // Draw main line
    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
  }

  void _drawLaneArea(Canvas canvas, Size size, LaneLine leftLane, LaneLine rightLane) {
    final areaPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.2)
      ..style = PaintingStyle.fill;

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

    canvas.drawPath(path, areaPaint);
  }

  @override
  bool shouldRepaint(LaneOverlayPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
