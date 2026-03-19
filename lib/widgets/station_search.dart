import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/models/station.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/theme.dart';

class StationSearch extends StatefulWidget {
  final Station? preselectedStation;

  const StationSearch({super.key, this.preselectedStation});

  @override
  State<StationSearch> createState() => _StationSearchState();
}

class _StationSearchState extends State<StationSearch> {
  Station? _selectedStation;
  int _alertMinutes = 5;
  final _searchController = TextEditingController();
  final _customMinutesController = TextEditingController();
  bool _showCustomMinutes = false;

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.preselectedStation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mistDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child:
                  _selectedStation == null
                      ? _buildSearchView()
                      : _buildTimingView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    final stations = context.watch<StationProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Destination',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search station...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (q) => stations.setSearchQuery(q),
        ),
        const SizedBox(height: 12),
        if (stations.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (stations.error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppColors.mistDim,
                ),
                const SizedBox(height: 8),
                Text(
                  stations.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 350),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: stations.filteredStations.length,
              itemBuilder: (context, index) {
                final station = stations.filteredStations[index];
                final isFav = stations.isFavorite(station.locationSignature);
                return ListTile(
                      leading: Icon(
                        isFav ? Icons.star_rounded : Icons.train_rounded,
                        color: isFav ? AppColors.amber : AppColors.cyan,
                        size: 22,
                      ),
                      title: Text(station.name),
                      subtitle: Text(
                        station.locationSignature,
                        style: const TextStyle(fontSize: 12),
                      ),
                      dense: true,
                      onTap: () {
                        setState(() => _selectedStation = station);
                        stations.setSearchQuery('');
                      },
                    )
                    .animate()
                    .fadeIn(
                      duration: 200.ms,
                      delay: Duration(milliseconds: (30 * index).clamp(0, 300)),
                    )
                    .slideX(begin: 0.05, end: 0, duration: 200.ms);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTimingView() {
    final station = _selectedStation!;
    final presetMinutes = [2, 5, 10, 15];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedStation = null),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Set Alert Timing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selected station card
        Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.train_rounded, color: AppColors.cyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.white),
                        ),
                        Text(
                          station.locationSignature,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 20),

        Text(
          'Alert me before arrival:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),

        // Timing chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...presetMinutes.map(
              (m) => ChoiceChip(
                label: Text('$m min'),
                selected: _alertMinutes == m && !_showCustomMinutes,
                selectedColor: AppColors.cyan,
                labelStyle: TextStyle(
                  color:
                      _alertMinutes == m && !_showCustomMinutes
                          ? AppColors.navy
                          : AppColors.mist,
                  fontWeight: FontWeight.w600,
                ),
                onSelected:
                    (_) => setState(() {
                      _alertMinutes = m;
                      _showCustomMinutes = false;
                    }),
              ),
            ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _showCustomMinutes,
              selectedColor: AppColors.cyan,
              labelStyle: TextStyle(
                color: _showCustomMinutes ? AppColors.navy : AppColors.mist,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _showCustomMinutes = true),
            ),
          ],
        ),

        if (_showCustomMinutes) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Minutes before arrival',
              suffixText: 'min',
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) {
                _alertMinutes = parsed;
              }
            },
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _createAlarm(context),
            icon: const Icon(Icons.alarm_on_rounded),
            label: Text('Set Alarm ($_alertMinutes min before)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _createAlarm(BuildContext context) {
    final station = _selectedStation!;
    final auth = context.read<AuthProvider>();
    final alarms = context.read<AlarmProvider>();
    final stationProv = context.read<StationProvider>();

    alarms.createAlarmFromStation(
      stationId: station.locationSignature,
      stationName: station.name,
      latitude: station.latitude,
      longitude: station.longitude,
      alertMinutes: _alertMinutes,
      userId: auth.isSignedIn ? auth.user!.uid : null,
    );

    if (auth.isSignedIn) {
      stationProv.addRecentStation(auth.user!.uid, station);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm set for ${station.name} ($_alertMinutes min before)',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Would cancel the alarm
          },
        ),
      ),
    );
  }
}
