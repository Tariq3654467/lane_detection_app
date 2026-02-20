import 'lane_detection.dart';
import 'lane_departure_warning.dart';

/// Data model for tracking dashboard statistics
class DashboardData {
  // Session statistics
  DateTime sessionStartTime;
  int totalFramesProcessed;
  int framesWithLanesDetected;
  int totalWarnings;
  int totalDepartures;
  
  // Performance metrics
  double averageFps;
  double averageProcessingTime;
  double minProcessingTime;
  double maxProcessingTime;
  
  // Lane detection metrics
  double averageCurvature;
  double averageVehicleOffset;
  double minVehicleOffset;
  double maxVehicleOffset;
  
  // Warning history (last 50 entries)
  final List<WarningEntry> warningHistory;
  
  // Processing time history (for charts)
  final List<double> processingTimeHistory;
  
  // Vehicle offset history (for charts)
  final List<double> vehicleOffsetHistory;
  
  // FPS history (for charts)
  final List<double> fpsHistory;

  DashboardData({
    required this.sessionStartTime,
    this.totalFramesProcessed = 0,
    this.framesWithLanesDetected = 0,
    this.totalWarnings = 0,
    this.totalDepartures = 0,
    this.averageFps = 0.0,
    this.averageProcessingTime = 0.0,
    this.minProcessingTime = double.infinity,
    this.maxProcessingTime = 0.0,
    this.averageCurvature = 0.0,
    this.averageVehicleOffset = 0.0,
    this.minVehicleOffset = 0.0,
    this.maxVehicleOffset = 0.0,
    List<WarningEntry>? warningHistory,
    List<double>? processingTimeHistory,
    List<double>? vehicleOffsetHistory,
    List<double>? fpsHistory,
  })  : warningHistory = warningHistory ?? [],
        processingTimeHistory = processingTimeHistory ?? [],
        vehicleOffsetHistory = vehicleOffsetHistory ?? [],
        fpsHistory = fpsHistory ?? [];

  double get detectionSuccessRate {
    if (totalFramesProcessed == 0) return 0.0;
    return (framesWithLanesDetected / totalFramesProcessed) * 100;
  }

  Duration get sessionDuration {
    return DateTime.now().difference(sessionStartTime);
  }

  String get sessionDurationFormatted {
    final duration = sessionDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void updateWithFrame({
    required bool lanesDetected,
    required double processingTime,
    required double fps,
    LaneDetectionResult? result,
    LaneDepartureStatus? departureStatus,
  }) {
    totalFramesProcessed++;
    
    if (lanesDetected) {
      framesWithLanesDetected++;
    }
    
    // Update processing time metrics
    averageProcessingTime = 
        (averageProcessingTime * (totalFramesProcessed - 1) + processingTime) / totalFramesProcessed;
    
    if (processingTime < minProcessingTime) {
      minProcessingTime = processingTime;
    }
    if (processingTime > maxProcessingTime) {
      maxProcessingTime = processingTime;
    }
    
    // Update FPS
    averageFps = (averageFps * (totalFramesProcessed - 1) + fps) / totalFramesProcessed;
    
    // Track warning/departure
    if (departureStatus != null) {
      if (departureStatus == LaneDepartureStatus.departureLeft ||
          departureStatus == LaneDepartureStatus.departureRight) {
        totalDepartures++;
        warningHistory.add(WarningEntry(
          timestamp: DateTime.now(),
          type: departureStatus,
          severity: 'departure',
        ));
      } else if (departureStatus == LaneDepartureStatus.warningLeft ||
                 departureStatus == LaneDepartureStatus.warningRight) {
        totalWarnings++;
        warningHistory.add(WarningEntry(
          timestamp: DateTime.now(),
          type: departureStatus,
          severity: 'warning',
        ));
      }
      
      // Keep only last 50 warnings
      if (warningHistory.length > 50) {
        warningHistory.removeAt(0);
      }
    }
    
    // Update lane detection metrics
    if (result != null && result.lanesDetected) {
      if (result.curvature != null) {
        final count = framesWithLanesDetected;
        averageCurvature = (averageCurvature * (count - 1) + result.curvature!) / count;
      }
      
      if (result.vehicleOffset != null) {
        final offset = result.vehicleOffset!.abs();
        final count = framesWithLanesDetected;
        averageVehicleOffset = (averageVehicleOffset * (count - 1) + offset) / count;
        
        if (offset < minVehicleOffset || minVehicleOffset == 0.0) {
          minVehicleOffset = offset;
        }
        if (offset > maxVehicleOffset) {
          maxVehicleOffset = offset;
        }
      }
    }
    
    // Add to history for charts (keep last 100 entries)
    processingTimeHistory.add(processingTime);
    if (processingTimeHistory.length > 100) {
      processingTimeHistory.removeAt(0);
    }
    
    if (result?.vehicleOffset != null) {
      vehicleOffsetHistory.add(result!.vehicleOffset!.abs());
      if (vehicleOffsetHistory.length > 100) {
        vehicleOffsetHistory.removeAt(0);
      }
    }
    
    fpsHistory.add(fps);
    if (fpsHistory.length > 100) {
      fpsHistory.removeAt(0);
    }
  }

  DashboardData copy() {
    return DashboardData(
      sessionStartTime: sessionStartTime,
      totalFramesProcessed: totalFramesProcessed,
      framesWithLanesDetected: framesWithLanesDetected,
      totalWarnings: totalWarnings,
      totalDepartures: totalDepartures,
      averageFps: averageFps,
      averageProcessingTime: averageProcessingTime,
      minProcessingTime: minProcessingTime,
      maxProcessingTime: maxProcessingTime,
      averageCurvature: averageCurvature,
      averageVehicleOffset: averageVehicleOffset,
      minVehicleOffset: minVehicleOffset,
      maxVehicleOffset: maxVehicleOffset,
      warningHistory: List.from(warningHistory),
      processingTimeHistory: List.from(processingTimeHistory),
      vehicleOffsetHistory: List.from(vehicleOffsetHistory),
      fpsHistory: List.from(fpsHistory),
    );
  }
}

class WarningEntry {
  final DateTime timestamp;
  final LaneDepartureStatus type;
  final String severity; // 'warning' or 'departure'

  WarningEntry({
    required this.timestamp,
    required this.type,
    required this.severity,
  });
}

