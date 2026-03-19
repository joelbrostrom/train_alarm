enum AlarmStatus {
  active,
  tracking,
  approaching,
  triggered,
  snoozed,
  dismissed,
  completed,
}

class Alarm {
  final String id;
  final String? userId;
  final String stationId;
  final String stationName;
  final double stationLatitude;
  final double stationLongitude;
  final int alertMinutesBefore;
  final AlarmStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? triggeredAt;
  final String? nickname;

  // Live tracking state (not persisted)
  final double? currentDistanceMeters;
  final double? estimatedMinutesAway;

  Alarm({
    required this.id,
    this.userId,
    required this.stationId,
    required this.stationName,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.alertMinutesBefore,
    this.status = AlarmStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.triggeredAt,
    this.nickname,
    this.currentDistanceMeters,
    this.estimatedMinutesAway,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Alarm copyWith({
    AlarmStatus? status,
    DateTime? triggeredAt,
    double? currentDistanceMeters,
    double? estimatedMinutesAway,
    DateTime? updatedAt,
  }) {
    return Alarm(
      id: id,
      userId: userId,
      stationId: stationId,
      stationName: stationName,
      stationLatitude: stationLatitude,
      stationLongitude: stationLongitude,
      alertMinutesBefore: alertMinutesBefore,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      triggeredAt: triggeredAt ?? this.triggeredAt,
      nickname: nickname,
      currentDistanceMeters:
          currentDistanceMeters ?? this.currentDistanceMeters,
      estimatedMinutesAway: estimatedMinutesAway ?? this.estimatedMinutesAway,
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'userId': userId,
    'stationId': stationId,
    'stationName': stationName,
    'stationLatitude': stationLatitude,
    'stationLongitude': stationLongitude,
    'alertMinutesBefore': alertMinutesBefore,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'triggeredAt': triggeredAt?.toIso8601String(),
    'nickname': nickname,
  };

  factory Alarm.fromFirestoreMap(String id, Map<String, dynamic> map) {
    return Alarm(
      id: id,
      userId: map['userId'] as String?,
      stationId: map['stationId'] as String? ?? '',
      stationName: map['stationName'] as String? ?? '',
      stationLatitude: (map['stationLatitude'] as num?)?.toDouble() ?? 0,
      stationLongitude: (map['stationLongitude'] as num?)?.toDouble() ?? 0,
      alertMinutesBefore: map['alertMinutesBefore'] as int? ?? 5,
      status: AlarmStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => AlarmStatus.active,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      triggeredAt:
          map['triggeredAt'] != null
              ? DateTime.tryParse(map['triggeredAt'])
              : null,
      nickname: map['nickname'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case AlarmStatus.active:
      case AlarmStatus.tracking:
        return 'Tracking';
      case AlarmStatus.approaching:
        return 'Approaching';
      case AlarmStatus.triggered:
        return 'WAKE UP!';
      case AlarmStatus.snoozed:
        return 'Snoozed';
      case AlarmStatus.dismissed:
        return 'Dismissed';
      case AlarmStatus.completed:
        return 'Completed';
    }
  }

  bool get isLive =>
      status == AlarmStatus.active ||
      status == AlarmStatus.tracking ||
      status == AlarmStatus.approaching ||
      status == AlarmStatus.snoozed;
}
