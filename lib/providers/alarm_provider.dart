import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/services/alarm_engine.dart';
import 'package:sov_inte_forbi/services/audio_service.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';
import 'package:sov_inte_forbi/services/local_storage_service.dart';

class AlarmProvider extends ChangeNotifier {
  final FirestoreService _firestore;
  final AlarmEngine _engine;
  final AudioService _audio;
  final LocalStorageService _localStorage;

  List<Alarm> _alarms = [];
  bool _alarmTriggered = false;
  Alarm? _triggeredAlarm;
  int _dismissCount = 0;
  int? _pendingMilestone;

  AlarmProvider(
    this._firestore,
    this._engine,
    this._audio,
    this._localStorage,
  ) {
    _engine.onAlarmTrigger = _handleAlarmTrigger;
    _engine.onAlarmUpdate = _handleAlarmUpdate;
    _loadDismissCount();
  }

  Future<void> _loadDismissCount() async {
    _dismissCount = await _localStorage.getDismissCount();
    dev.log('Loaded dismiss count: $_dismissCount', name: 'Alarm');
    notifyListeners();
  }

  List<Alarm> get alarms => _alarms;
  List<Alarm> get activeAlarms => _alarms.where((a) => a.isLive).toList();
  bool get alarmTriggered => _alarmTriggered;
  Alarm? get triggeredAlarm => _triggeredAlarm;
  int get dismissCount => _dismissCount;
  int? get pendingMilestone => _pendingMilestone;

  void clearPendingMilestone() {
    _pendingMilestone = null;
    notifyListeners();
  }

  Future<void> loadAlarms(String userId) async {
    dev.log('Loading alarms for user=$userId', name: 'Alarm');
    try {
      _alarms = List<Alarm>.of(await _firestore.getAlarms(userId));
      dev.log(
        'Loaded ${_alarms.length} alarms (${activeAlarms.length} active)',
        name: 'Alarm',
      );
      notifyListeners();
      _startTrackingActiveAlarms();
    } catch (e) {
      dev.log('Load alarms error: $e', name: 'Alarm', level: 1000);
    }
  }

  Alarm createAlarmFromStation({
    required String stationId,
    required String stationName,
    required double latitude,
    required double longitude,
    required int alertMinutes,
    String? userId,
    String? nickname,
  }) {
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
    dev.log(
      'Created alarm: id=${alarm.id}, station=$stationName ($stationId), '
      'alertMinutes=$alertMinutes, userId=$userId',
      name: 'Alarm',
    );
    notifyListeners();

    _localStorage.incrementStationUsage(stationId);

    if (userId != null) {
      _firestore.saveAlarm(userId, alarm);
    }

    _engine.startTracking(alarm);
    return alarm;
  }

  void _handleAlarmTrigger(Alarm alarm) {
    dev.log(
      'ALARM TRIGGERED: ${alarm.stationName} (${alarm.id}), '
      'distance=${alarm.currentDistanceMeters?.toStringAsFixed(0)}m',
      name: 'Alarm',
    );
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
      final wasApproaching = _alarms[idx].status == AlarmStatus.approaching;
      _alarms[idx] = alarm;
      if (!wasApproaching && alarm.status == AlarmStatus.approaching) {
        dev.log(
          'Alarm approaching: ${alarm.stationName}, '
          'ETA=${alarm.estimatedMinutesAway?.toStringAsFixed(1)}min',
          name: 'Alarm',
        );
        _audio.playApproachingChime();
      }
      notifyListeners();
    }
  }

  Future<void> dismissAlarm(String alarmId) async {
    dev.log('Dismissing alarm: $alarmId', name: 'Alarm');
    final idx = _alarms.indexWhere((a) => a.id == alarmId);
    if (idx >= 0) {
      _alarms[idx] = _alarms[idx].copyWith(status: AlarmStatus.dismissed);
      _engine.stopTracking(alarmId);
      _audio.stopAlarm();
      _alarmTriggered = false;
      _triggeredAlarm = null;

      _dismissCount = await _localStorage.incrementDismissCount();
      await _checkMilestone();

      notifyListeners();

      final userId = _alarms[idx].userId;
      if (userId != null) {
        await _firestore.saveAlarm(userId, _alarms[idx]);
      }
    }
  }

  Future<void> _checkMilestone() async {
    const milestones = [1, 10, 25, 50, 100, 250, 500];
    final lastMilestone = await _localStorage.getLastMilestone();
    for (final m in milestones) {
      if (_dismissCount >= m && lastMilestone < m) {
        _pendingMilestone = m;
        await _localStorage.setLastMilestone(m);
        break;
      }
    }
  }

  Future<void> snoozeAlarm(String alarmId) async {
    dev.log('Snoozing alarm: $alarmId (will re-trigger in 30s)', name: 'Alarm');
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
    dev.log('Cancelling alarm: $alarmId', name: 'Alarm');
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
    dev.log('Testing alarm sound (3s)', name: 'Alarm');
    _audio.playAlarm();
    Future.delayed(const Duration(seconds: 3), () => _audio.stopAlarm());
  }

  void _startTrackingActiveAlarms() {
    dev.log(
      'Starting tracking for ${activeAlarms.length} active alarms',
      name: 'Alarm',
    );
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
