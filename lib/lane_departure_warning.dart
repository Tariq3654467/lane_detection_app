import 'lane_detection.dart';

/// Lane Departure Warning System
class LaneDepartureWarningSystem {
  static const double departureThreshold = 0.3; // meters
  static const double warningThreshold = 0.2; // meters

  /// Check for lane departure
  static LaneDepartureStatus checkDeparture(LaneDetectionResult result) {
    if (!result.lanesDetected || result.vehicleOffset == null) {
      return LaneDepartureStatus.normal;
    }

    final offset = result.vehicleOffset!.abs();

    if (offset > departureThreshold) {
      return result.vehicleOffset! > 0
          ? LaneDepartureStatus.departureRight
          : LaneDepartureStatus.departureLeft;
    } else if (offset > warningThreshold) {
      return result.vehicleOffset! > 0
          ? LaneDepartureStatus.warningRight
          : LaneDepartureStatus.warningLeft;
    }

    return LaneDepartureStatus.normal;
  }

  /// Get steering suggestion based on lane detection
  static SteeringSuggestion getSteeringSuggestion(LaneDetectionResult result) {
    if (!result.lanesDetected || result.vehicleOffset == null) {
      return SteeringSuggestion.unknown;
    }

    final offset = result.vehicleOffset!;

    if (offset.abs() < 0.1) {
      return SteeringSuggestion.straight;
    } else if (offset > 0.2) {
      return SteeringSuggestion.steerLeft;
    } else if (offset < -0.2) {
      return SteeringSuggestion.steerRight;
    } else if (offset > 0) {
      return SteeringSuggestion.slightLeft;
    } else {
      return SteeringSuggestion.slightRight;
    }
  }
}

enum LaneDepartureStatus {
  normal,
  warningLeft,
  warningRight,
  departureLeft,
  departureRight,
}

enum SteeringSuggestion {
  unknown,
  straight,
  slightLeft,
  slightRight,
  steerLeft,
  steerRight,
}

