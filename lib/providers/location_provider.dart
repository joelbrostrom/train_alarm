import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;

  LocationData? _currentPosition;
  bool _hasPermission = false;
  bool _loading = false;
  String? _error;
  StreamSubscription? _positionSub;

  LocationProvider(this._locationService);

  LocationData? get currentPosition => _currentPosition;
  bool get hasPermission => _hasPermission;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    dev.log('Initializing location provider...', name: 'Location');
    _loading = true;
    notifyListeners();

    try {
      _hasPermission = await _locationService.checkPermission();
      dev.log('Location permission: $_hasPermission', name: 'Location');

      if (_hasPermission) {
        _startListening();
      }
    } catch (e) {
      dev.log('Location init error: $e', name: 'Location', level: 1000);
      _hasPermission = false;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> requestPermission() async {
    dev.log('Requesting location permission...', name: 'Location');
    _hasPermission = await _locationService.requestPermission();
    dev.log('Permission result: $_hasPermission', name: 'Location');
    if (_hasPermission) {
      _startListening();
    }
    notifyListeners();
  }

  void _startListening() {
    dev.log('Starting location stream', name: 'Location');
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream.listen(
      (pos) {
        _currentPosition = pos;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Location unavailable';
        dev.log('Location stream error: $e', name: 'Location', level: 1000);
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
