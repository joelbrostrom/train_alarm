class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? homeAddress;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? homeStationId;
  final String? homeStationName;
  final int defaultAlertMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.homeAddress,
    this.homeLatitude,
    this.homeLongitude,
    this.homeStationId,
    this.homeStationName,
    this.defaultAlertMinutes = 5,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  AppUser copyWith({
    String? homeAddress,
    double? homeLatitude,
    double? homeLongitude,
    String? homeStationId,
    String? homeStationName,
    int? defaultAlertMinutes,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      homeAddress: homeAddress ?? this.homeAddress,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      homeStationId: homeStationId ?? this.homeStationId,
      homeStationName: homeStationName ?? this.homeStationName,
      defaultAlertMinutes: defaultAlertMinutes ?? this.defaultAlertMinutes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'homeAddress': homeAddress,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'homeStationId': homeStationId,
    'homeStationName': homeStationName,
    'defaultAlertMinutes': defaultAlertMinutes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AppUser.fromFirestoreMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      homeAddress: map['homeAddress'] as String?,
      homeLatitude: (map['homeLatitude'] as num?)?.toDouble(),
      homeLongitude: (map['homeLongitude'] as num?)?.toDouble(),
      homeStationId: map['homeStationId'] as String?,
      homeStationName: map['homeStationName'] as String?,
      defaultAlertMinutes: map['defaultAlertMinutes'] as int? ?? 5,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
