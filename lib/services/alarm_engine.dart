import 'dart:async';
import 'dart:math';

import 'package:sov_inte_forbi/config.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/services/location_service.dart';

class AlarmEngine {
  final LocationService _locationService;

  final Map<String, StreamSubscription> _trackingSubs = {};
  final Map<String, List<LocationData>> _positionBuffers = {};

  void Function(Alarm alarm)? onAlarmTrigger;
  void Function(Alarm alarm)? onAlarmUpdate;

  AlarmEngine(this._locationService);

  void startTracking(Alarm alarm) {
    stopTracking(alarm.id);

    _positionBuffers[alarm.id] = [];

    _trackingSubs[alarm.id] = _locationService.positionStream.listen((pos) {
      _onPositionUpdate(alarm, pos);
    });
  }

  void stopTracking(String alarmId) {
    _trackingSubs[alarmId]?.cancel();
    _trackingSubs.remove(alarmId);
    _positionBuffers.remove(alarmId);
  }

  void _onPositionUpdate(Alarm alarm, LocationData position) {
    final buffer = _positionBuffers[alarm.id];
    if (buffer == null) return;

    buffer.add(position);
    if (buffer.length > positionBufferSize) {
      buffer.removeAt(0);
    }

    final distanceMeters = _haversineDistance(
      position.latitude,
      position.longitude,
      alarm.stationLatitude,
      alarm.stationLongitude,
    );

    final speedMps = _estimateSpeed(buffer);
    final etaMinutes = _calculateEta(distanceMeters, speedMps);

    final updatedAlarm = alarm.copyWith(
      currentDistanceMeters: distanceMeters,
      estimatedMinutesAway: etaMinutes,
      status:
          etaMinutes != null && etaMinutes <= alarm.alertMinutesBefore * 2
              ? AlarmStatus.approaching
              : AlarmStatus.tracking,
    );

    onAlarmUpdate?.call(updatedAlarm);

    final shouldTrigger =
        distanceMeters <= minimumTriggerDistanceMeters ||
        (etaMinutes != null && etaMinutes <= alarm.alertMinutesBefore);

    if (shouldTrigger) {
      stopTracking(alarm.id);
      onAlarmTrigger?.call(updatedAlarm);
    }
  }

  double? _estimateSpeed(List<LocationData> buffer) {
    if (buffer.length < 2) return null;

    double totalDistance = 0;
    double totalTimeSeconds = 0;

    for (int i = 1; i < buffer.length; i++) {
      final prev = buffer[i - 1];
      final curr = buffer[i];

      totalDistance += _haversineDistance(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      totalTimeSeconds +=
          curr.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
    }

    if (totalTimeSeconds <= 0) return null;
    final speedMps = totalDistance / totalTimeSeconds;

    // Filter out unreasonable speeds (> 300 km/h)
    if (speedMps > 83) return null;

    return speedMps;
  }

  double? _calculateEta(double distanceMeters, double? speedMps) {
    if (speedMps == null || speedMps < 0.5) {
      // Use fallback train speed
      return distanceMeters / (fallbackTrainSpeedKmh * 1000 / 60);
    }
    return (distanceMeters / speedMps) / 60.0;
  }

  /// Haversine formula returning distance in meters
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  void dispose() {
    for (final sub in _trackingSubs.values) {
      sub.cancel();
    }
    _trackingSubs.clear();
    _positionBuffers.clear();
  }
}
