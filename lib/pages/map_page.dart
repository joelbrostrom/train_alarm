import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/models/station.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/location_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/theme.dart';
import 'package:sov_inte_forbi/widgets/station_search.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationProvider>();
    final location = context.watch<LocationProvider>();
    final alarms = context.watch<AlarmProvider>();

    final userPos = location.currentPosition;
    final center =
        userPos != null
            ? LatLng(userPos.latitude, userPos.longitude)
            : const LatLng(62.0, 15.0); // Center of Sweden

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: userPos != null ? 10 : 5,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'se.sovintegorbi.app',
            ),
            MarkerLayer(
              markers: [
                if (userPos != null)
                  Marker(
                    point: LatLng(userPos.latitude, userPos.longitude),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ...stations.allStations.map(
                  (s) => Marker(
                    point: LatLng(s.latitude, s.longitude),
                    width: 32,
                    height: 32,
                    child: GestureDetector(
                      onTap: () => _showStationDetail(context, s),
                      child: _StationMarkerDot(
                        isFavorite: stations.isFavorite(s.locationSignature),
                        hasActiveAlarm: alarms.activeAlarms.any(
                          (a) => a.stationId == s.locationSignature,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Alarm radius circles
            CircleLayer(
              circles:
                  alarms.activeAlarms
                      .map(
                        (a) => CircleMarker(
                          point: LatLng(a.stationLatitude, a.stationLongitude),
                          radius: 2000,
                          useRadiusInMeter: true,
                          color: AppColors.cyan.withValues(alpha: 0.08),
                          borderColor: AppColors.cyan.withValues(alpha: 0.3),
                          borderStrokeWidth: 1.5,
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        // Recenter button
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: AppColors.navySurface,
            onPressed: () {
              if (userPos != null) {
                _mapController.move(
                  LatLng(userPos.latitude, userPos.longitude),
                  12,
                );
              }
            },
            child: const Icon(Icons.my_location_rounded, color: AppColors.cyan),
          ),
        ),
      ],
    );
  }

  void _showStationDetail(BuildContext context, Station station) {
    final auth = context.read<AuthProvider>();
    final stationProv = context.read<StationProvider>();
    final alarmProv = context.read<AlarmProvider>();
    final location = context.read<LocationProvider>();

    final userPos = location.currentPosition;
    String? distanceText;
    if (userPos != null) {
      final dist = const Distance().as(
        LengthUnit.Kilometer,
        LatLng(userPos.latitude, userPos.longitude),
        LatLng(station.latitude, station.longitude),
      );
      distanceText = '${dist.toStringAsFixed(1)} km away';
    }

    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.train_rounded, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        station.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (auth.isSignedIn)
                      IconButton(
                        onPressed: () {
                          stationProv.toggleFavorite(station, auth.user!.uid);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          stationProv.isFavorite(station.locationSignature)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.amber,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  station.locationSignature,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (distanceText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    distanceText,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.cyan),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _createAlarmForStation(context, station, alarmProv, auth);
                    },
                    icon: const Icon(Icons.alarm_add_rounded),
                    label: const Text('Set Alarm'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _createAlarmForStation(
    BuildContext context,
    Station station,
    AlarmProvider alarmProv,
    AuthProvider auth,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(
                value: context.read<StationProvider>(),
              ),
              ChangeNotifierProvider.value(
                value: context.read<AlarmProvider>(),
              ),
              ChangeNotifierProvider.value(value: context.read<AuthProvider>()),
            ],
            child: StationSearch(preselectedStation: station),
          ),
    );
  }
}

class _StationMarkerDot extends StatelessWidget {
  final bool isFavorite;
  final bool hasActiveAlarm;

  const _StationMarkerDot({
    required this.isFavorite,
    required this.hasActiveAlarm,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        hasActiveAlarm
            ? AppColors.coral
            : isFavorite
            ? AppColors.amber
            : AppColors.skyBlue;

    return Container(
      width: hasActiveAlarm ? 16 : 10,
      height: hasActiveAlarm ? 16 : 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy, width: 2),
        boxShadow: [
          if (hasActiveAlarm)
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}
