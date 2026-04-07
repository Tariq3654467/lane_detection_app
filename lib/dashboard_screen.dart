import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_data.dart';
import 'lane_departure_warning.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardData data;

  const DashboardScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, isDark, colorScheme),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGlassCard(
                      isDark: isDark,
                      child: _buildSessionInfoCard(isDark),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Performance Metrics', Icons.speed, colorScheme.primary),
                    const SizedBox(height: 12),
                    _buildMetricsRow(isDark, colorScheme),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Detection Statistics', Icons.analytics, colorScheme.secondary),
                    const SizedBox(height: 12),
                    _buildStatCards(isDark, colorScheme),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Lane Metrics', Icons.timeline, Colors.purple),
                    const SizedBox(height: 12),
                    _buildLaneMetricsRow(isDark),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Warning Statistics', Icons.warning_amber, Colors.orange),
                    const SizedBox(height: 12),
                    _buildWarningRow(isDark, colorScheme),
                    const SizedBox(height: 20),
                    if (data.warningHistory.isNotEmpty) ...[
                      _buildSectionHeader('Recent Warnings', Icons.history, Colors.red),
                      const SizedBox(height: 12),
                      _buildWarningHistory(isDark),
                      const SizedBox(height: 20),
                    ],
                    if (data.processingTimeHistory.isNotEmpty) ...[
                      _buildSectionHeader('Processing Time Trend', Icons.show_chart, Colors.blue),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDark: isDark,
                        child: _buildChart(data.processingTimeHistory, 'ms', Colors.blue),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (data.fpsHistory.isNotEmpty) ...[
                      _buildSectionHeader('FPS Trend', Icons.monitor_heart, Colors.green),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDark: isDark,
                        child: _buildChart(data.fpsHistory, 'FPS', Colors.green),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (data.vehicleOffsetHistory.isNotEmpty) ...[
                      _buildSectionHeader('Vehicle Offset Trend', Icons.straighten, Colors.purple),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDark: isDark,
                        child: _buildChart(data.vehicleOffsetHistory, 'm', Colors.purple),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                Text(
                  'Real-time monitoring stats',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfoCard(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              'Session Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Session Duration', data.sessionDurationFormatted, isDark),
        const SizedBox(height: 10),
        _buildInfoRow('Total Frames', data.totalFramesProcessed.toString(), isDark),
        const SizedBox(height: 10),
        _buildInfoRow('Detection Rate', '${data.detectionSuccessRate.toStringAsFixed(1)}%', isDark),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(bool isDark, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Average FPS', data.averageFps.toStringAsFixed(1), Icons.speed, Colors.green, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Avg Processing', '${data.averageProcessingTime.toStringAsFixed(1)}ms', Icons.timer, Colors.blue, isDark)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildStatCards(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Frames', data.totalFramesProcessed.toString(), Icons.videocam, Colors.purple, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Detection Rate', '${data.detectionSuccessRate.toStringAsFixed(1)}%', Icons.check_circle, data.detectionSuccessRate > 50 ? Colors.green : Colors.orange, isDark)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('Frames with Lanes', data.framesWithLanesDetected.toString(), Icons.alt_route, Colors.teal, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaneMetricsRow(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard('Avg Curvature', data.averageCurvature.toStringAsFixed(2), Icons.timeline, Colors.indigo, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Avg Offset', '${data.averageVehicleOffset.toStringAsFixed(2)}m', Icons.center_focus_strong, Colors.deepPurple, isDark)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Min Offset', '${data.minVehicleOffset.toStringAsFixed(2)}m', Icons.arrow_downward, Colors.green, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Max Offset', '${data.maxVehicleOffset.toStringAsFixed(2)}m', Icons.arrow_upward, Colors.red, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningRow(bool isDark, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildWarningCard('Total Warnings', data.totalWarnings.toString(), Icons.warning_amber, Colors.orange, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildWarningCard('Total Departures', data.totalDepartures.toString(), Icons.dangerous, Colors.red, isDark)),
      ],
    );
  }

  Widget _buildWarningCard(String label, String value, IconData icon, Color color, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWarningHistory(bool isDark) {
    final recentWarnings = data.warningHistory.length > 10
        ? data.warningHistory.sublist(data.warningHistory.length - 10)
        : data.warningHistory;
    return _buildGlassCard(
      isDark: isDark,
      child: Column(children: recentWarnings.reversed.map((warning) => _buildWarningListItem(warning, isDark)).toList()),
    );
  }

  Widget _buildWarningListItem(WarningEntry warning, bool isDark) {
    final isWarning = warning.severity == 'warning';
    final color = isWarning ? Colors.orange : Colors.red;
    final icon = isWarning ? Icons.warning_amber : Icons.dangerous;
    String typeText = '';
    switch (warning.type) {
      case LaneDepartureStatus.warningLeft: typeText = 'Warning: Drifting Left'; break;
      case LaneDepartureStatus.warningRight: typeText = 'Warning: Drifting Right'; break;
      case LaneDepartureStatus.departureLeft: typeText = 'ALERT: Lane Departure Left'; break;
      case LaneDepartureStatus.departureRight: typeText = 'ALERT: Lane Departure Right'; break;
      default: typeText = 'Normal';
    }
    final timeAgo = DateTime.now().difference(warning.timestamp);
    String timeText = timeAgo.inSeconds < 60 ? '${timeAgo.inSeconds}s ago' : (timeAgo.inMinutes < 60 ? '${timeAgo.inMinutes}m ago' : '${timeAgo.inHours}h ago');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(timeText, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> data, String label, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: SimpleLineChartPainter(data: data, color: color, minValue: data.reduce((a, b) => a < b ? a : b), maxValue: data.reduce((a, b) => a > b ? a : b)),
        child: Container(),
      ),
    );
  }
}

class SimpleLineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;

  SimpleLineChartPainter({required this.data, required this.color, required this.minValue, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 3.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final gradientPaint = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final range = maxValue - minValue;
    if (range == 0) return;
    final path = Path();
    final areaPath = Path();
    final stepX = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();
    canvas.drawPath(areaPath, gradientPaint);
    canvas.drawPath(path, paint);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(SimpleLineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color || oldDelegate.minValue != minValue || oldDelegate.maxValue != maxValue;
  }
}
