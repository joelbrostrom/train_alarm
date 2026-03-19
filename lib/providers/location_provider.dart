import 'dart:async';

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
    _loading = true;
    notifyListeners();

    _hasPermission = await _locationService.checkPermission();

    if (_hasPermission) {
      _startListening();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> requestPermission() async {
    _hasPermission = await _locationService.requestPermission();
    if (_hasPermission) {
      _startListening();
    }
    notifyListeners();
  }

  void _startListening() {
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream.listen(
      (pos) {
        _currentPosition = pos;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Location unavailable';
        print('Location error: $e');
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
