class Station {
  final String locationSignature;
  final String name;
  final double latitude;
  final double longitude;
  final List<int> countyNumbers;

  Station({
    required this.locationSignature,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.countyNumbers = const [],
  });

  factory Station.fromTrafikverketJson(Map<String, dynamic> json) {
    final wgs84 = json['Geometry']?['WGS84'] as String? ?? '';
    final coords = _parseWgs84Point(wgs84);

    final countyRaw = json['CountyNo'];
    final counties = <int>[];
    if (countyRaw is List) {
      for (final c in countyRaw) {
        if (c is int) counties.add(c);
        if (c is num) counties.add(c.toInt());
      }
    }

    return Station(
      locationSignature: json['LocationSignature'] as String? ?? '',
      name: json['AdvertisedLocationName'] as String? ?? '',
      latitude: coords.$1,
      longitude: coords.$2,
      countyNumbers: counties,
    );
  }

  static (double lat, double lon) _parseWgs84Point(String wgs84) {
    // Format: "POINT (lon lat)"
    final match = RegExp(
      r'POINT\s*\(\s*([\d.]+)\s+([\d.]+)\s*\)',
    ).firstMatch(wgs84);
    if (match == null) return (0.0, 0.0);
    final lon = double.tryParse(match.group(1)!) ?? 0.0;
    final lat = double.tryParse(match.group(2)!) ?? 0.0;
    return (lat, lon);
  }

  Map<String, dynamic> toFirestoreMap() => {
    'stationId': locationSignature,
    'stationName': name,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  String toString() => 'Station($name, $locationSignature)';

  @override
  bool operator ==(Object other) =>
      other is Station && other.locationSignature == locationSignature;

  @override
  int get hashCode => locationSignature.hashCode;
}
