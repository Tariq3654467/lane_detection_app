import 'package:flutter/material.dart';
import 'dashboard_data.dart';
import 'lane_departure_warning.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardData data;

  const DashboardScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Info Card
            _buildSessionInfoCard(),
            const SizedBox(height: 16),
            
            // Performance Metrics
            _buildSectionTitle('Performance Metrics'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Average FPS',
                  data.averageFps.toStringAsFixed(1),
                  Icons.speed,
                  Colors.green,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Avg Processing',
                  '${data.averageProcessingTime.toStringAsFixed(1)}ms',
                  Icons.timer,
                  Colors.blue,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Min Time',
                  data.minProcessingTime == double.infinity 
                      ? 'N/A' 
                      : '${data.minProcessingTime.toStringAsFixed(1)}ms',
                  Icons.trending_down,
                  Colors.cyan,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Max Time',
                  '${data.maxProcessingTime.toStringAsFixed(1)}ms',
                  Icons.trending_up,
                  Colors.orange,
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            // Detection Statistics
            _buildSectionTitle('Detection Statistics'),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Frames',
              data.totalFramesProcessed.toString(),
              Icons.videocam,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Detection Rate',
              '${data.detectionSuccessRate.toStringAsFixed(1)}%',
              Icons.check_circle,
              data.detectionSuccessRate > 50 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Frames with Lanes',
              data.framesWithLanesDetected.toString(),
              Icons.alt_route,
              Colors.teal,
            ),
            const SizedBox(height: 24),
            
            // Lane Metrics
            _buildSectionTitle('Lane Metrics'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Avg Curvature',
                  data.averageCurvature.toStringAsFixed(2),
                  Icons.curved_lines,
                  Colors.indigo,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Avg Offset',
                  '${data.averageVehicleOffset.toStringAsFixed(2)}m',
                  Icons.center_focus_strong,
                  Colors.deepPurple,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Min Offset',
                  '${data.minVehicleOffset.toStringAsFixed(2)}m',
                  Icons.arrow_downward,
                  Colors.green,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(
                  'Max Offset',
                  '${data.maxVehicleOffset.toStringAsFixed(2)}m',
                  Icons.arrow_upward,
                  Colors.red,
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            // Warning Statistics
            _buildSectionTitle('Warning Statistics'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildWarningCard(
                  'Total Warnings',
                  data.totalWarnings.toString(),
                  Icons.warning,
                  Colors.orange,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildWarningCard(
                  'Total Departures',
                  data.totalDepartures.toString(),
                  Icons.dangerous,
                  Colors.red,
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            // Recent Warnings
            if (data.warningHistory.isNotEmpty) ...[
              _buildSectionTitle('Recent Warnings'),
              const SizedBox(height: 12),
              _buildWarningHistory(),
              const SizedBox(height: 24),
            ],
            
            // Processing Time Chart
            if (data.processingTimeHistory.isNotEmpty) ...[
              _buildSectionTitle('Processing Time Trend'),
              const SizedBox(height: 12),
              _buildSimpleChart(
                data.processingTimeHistory,
                'Time (ms)',
                Colors.blue,
              ),
              const SizedBox(height: 24),
            ],
            
            // FPS Chart
            if (data.fpsHistory.isNotEmpty) ...[
              _buildSectionTitle('FPS Trend'),
              const SizedBox(height: 12),
              _buildSimpleChart(
                data.fpsHistory,
                'FPS',
                Colors.green,
              ),
              const SizedBox(height: 24),
            ],
            
            // Vehicle Offset Chart
            if (data.vehicleOffsetHistory.isNotEmpty) ...[
              _buildSectionTitle('Vehicle Offset Trend'),
              const SizedBox(height: 12),
              _buildSimpleChart(
                data.vehicleOffsetHistory,
                'Offset (m)',
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Session Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Session Duration', data.sessionDurationFormatted),
          const SizedBox(height: 8),
          _buildInfoRow('Total Frames', data.totalFramesProcessed.toString()),
          const SizedBox(height: 8),
          _buildInfoRow('Detection Rate', '${data.detectionSuccessRate.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningHistory() {
    final recentWarnings = data.warningHistory.length > 10
        ? data.warningHistory.sublist(data.warningHistory.length - 10)
        : data.warningHistory;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentWarnings.length,
        itemBuilder: (context, index) {
          final warning = recentWarnings[recentWarnings.length - 1 - index];
          return _buildWarningListItem(warning);
        },
      ),
    );
  }

  Widget _buildWarningListItem(WarningEntry warning) {
    final isWarning = warning.severity == 'warning';
    final color = isWarning ? Colors.orange : Colors.red;
    final icon = isWarning ? Icons.warning : Icons.dangerous;
    
    String typeText = '';
    switch (warning.type) {
      case LaneDepartureStatus.warningLeft:
        typeText = 'Warning: Drifting Left';
        break;
      case LaneDepartureStatus.warningRight:
        typeText = 'Warning: Drifting Right';
        break;
      case LaneDepartureStatus.departureLeft:
        typeText = 'ALERT: Lane Departure Left';
        break;
      case LaneDepartureStatus.departureRight:
        typeText = 'ALERT: Lane Departure Right';
        break;
      default:
        typeText = 'Normal';
    }

    final timeAgo = DateTime.now().difference(warning.timestamp);
    String timeText;
    if (timeAgo.inSeconds < 60) {
      timeText = '${timeAgo.inSeconds}s ago';
    } else if (timeAgo.inMinutes < 60) {
      timeText = '${timeAgo.inMinutes}m ago';
    } else {
      timeText = '${timeAgo.inHours}h ago';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<double> data, String label, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: SimpleLineChartPainter(
          data: data,
          color: color,
          minValue: minValue,
          maxValue: maxValue,
        ),
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

  SimpleLineChartPainter({
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final range = maxValue - minValue;
    if (range == 0) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw area under curve
    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(SimpleLineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }
}

