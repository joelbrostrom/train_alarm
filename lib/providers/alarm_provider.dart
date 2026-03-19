import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/services/alarm_engine.dart';
import 'package:sov_inte_forbi/services/audio_service.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';

class AlarmProvider extends ChangeNotifier {
  final FirestoreService _firestore;
  final AlarmEngine _engine;
  final AudioService _audio;

  List<Alarm> _alarms = [];
  bool _alarmTriggered = false;
  Alarm? _triggeredAlarm;

  AlarmProvider(this._firestore, this._engine, this._audio) {
    _engine.onAlarmTrigger = _handleAlarmTrigger;
    _engine.onAlarmUpdate = _handleAlarmUpdate;
  }

  List<Alarm> get alarms => _alarms;
  List<Alarm> get activeAlarms => _alarms.where((a) => a.isLive).toList();
  bool get alarmTriggered => _alarmTriggered;
  Alarm? get triggeredAlarm => _triggeredAlarm;

  Future<void> loadAlarms(String userId) async {
    try {
      _alarms = await _firestore.getAlarms(userId);
      notifyListeners();
      _startTrackingActiveAlarms();
    } catch (e) {
      print('Load alarms error: $e');
    }
  }

  Future<void> createAlarmFromStation({
    required String stationId,
    required String stationName,
    required double latitude,
    required double longitude,
    required int alertMinutes,
    String? userId,
    String? nickname,
  }) async {
    final alarm = Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      stationId: stationId,
      stationName: stationName,
      stationLatitude: latitude,
      stationLongitude: longitude,
      alertMinutesBefore: alertMinutes,
      status: AlarmStatus.active,
      nickname: nickname,
    );

    _alarms.insert(0, alarm);
    notifyListeners();

    if (userId != null) {
      await _firestore.saveAlarm(userId, alarm);
    }

    _engine.startTracking(alarm);
  }

  void _handleAlarmTrigger(Alarm alarm) {
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      _alarms[idx] = alarm.copyWith(
        status: AlarmStatus.triggered,
        triggeredAt: DateTime.now(),
      );
    }
    _alarmTriggered = true;
    _triggeredAlarm = _alarms[idx];
    _audio.playAlarm();
    notifyListeners();
  }

  void _handleAlarmUpdate(Alarm alarm) {
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      _alarms[idx] = alarm;
      notifyListeners();
    }
  }

  Future<void> dismissAlarm(String alarmId) async {
    final idx = _alarms.indexWhere((a) => a.id == alarmId);
    if (idx >= 0) {
      _alarms[idx] = _alarms[idx].copyWith(status: AlarmStatus.dismissed);
      _engine.stopTracking(alarmId);
      _audio.stopAlarm();
      _alarmTriggered = false;
      _triggeredAlarm = null;
      notifyListeners();

      final userId = _alarms[idx].userId;
      if (userId != null) {
        await _firestore.saveAlarm(userId, _alarms[idx]);
      }
    }
  }

  Future<void> snoozeAlarm(String alarmId) async {
    final idx = _alarms.indexWhere((a) => a.id == alarmId);
    if (idx >= 0) {
      _alarms[idx] = _alarms[idx].copyWith(status: AlarmStatus.snoozed);
      _audio.stopAlarm();
      _alarmTriggered = false;
      _triggeredAlarm = null;
      notifyListeners();

      // Re-trigger after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        final current = _alarms.indexWhere((a) => a.id == alarmId);
        if (current >= 0 && _alarms[current].status == AlarmStatus.snoozed) {
          _engine.startTracking(_alarms[current]);
        }
      });
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    final idx = _alarms.indexWhere((a) => a.id == alarmId);
    if (idx >= 0) {
      _engine.stopTracking(alarmId);
      _audio.stopAlarm();
      final alarm = _alarms[idx].copyWith(status: AlarmStatus.completed);
      _alarms[idx] = alarm;
      _alarmTriggered = false;
      _triggeredAlarm = null;
      notifyListeners();

      if (alarm.userId != null) {
        await _firestore.saveAlarm(alarm.userId!, alarm);
      }
    }
  }

  void testAlarmSound() {
    _audio.playAlarm();
    Future.delayed(const Duration(seconds: 3), () => _audio.stopAlarm());
  }

  void _startTrackingActiveAlarms() {
    for (final alarm in activeAlarms) {
      _engine.startTracking(alarm);
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    _audio.dispose();
    super.dispose();
  }
}
