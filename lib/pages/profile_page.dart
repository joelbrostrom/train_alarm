import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/models/station.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/location_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = context.watch<LocationProvider>();
    final isWide = MediaQuery.of(context).size.width > 800;

    if (!auth.isSignedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_rounded, size: 64, color: AppColors.mistDim),
              const SizedBox(height: 16),
              Text(
                'Sign in to view your profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => auth.signInWithGoogle(),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.user!;

    return CustomScrollView(
      slivers: [
        if (!isWide) const SliverAppBar(floating: true, title: Text('Profile')),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // User info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.cyan,
                        backgroundImage:
                            user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child:
                            user.photoUrl == null
                                ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Settings
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.home_rounded,
                        color: AppColors.skyBlue,
                      ),
                      title: const Text('Home Station'),
                      subtitle: Text(user.homeStationName ?? 'Not set'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editHomeStation(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(
                        Icons.timer_rounded,
                        color: AppColors.cyan,
                      ),
                      title: const Text('Default Alert Time'),
                      subtitle: Text(
                        '${user.defaultAlertMinutes} minutes before',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editDefaultMinutes(context, auth),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(
                        Icons.location_on_rounded,
                        color:
                            location.hasPermission
                                ? AppColors.cyan
                                : AppColors.coral,
                      ),
                      title: const Text('Location Permission'),
                      subtitle: Text(
                        location.hasPermission ? 'Granted' : 'Not granted',
                      ),
                      trailing:
                          location.hasPermission
                              ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.cyan,
                              )
                              : TextButton(
                                onPressed: () => location.requestPermission(),
                                child: const Text('Enable'),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.amber,
                      ),
                      title: const Text('Test Alarm Sound'),
                      subtitle: const Text('Tap to verify audio works'),
                      onTap:
                          () => context.read<AlarmProvider>().testAlarmSound(),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.coral,
                      ),
                      title: const Text('Sign Out'),
                      onTap: () => auth.signOut(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  void _editHomeStation(BuildContext context) {
    final stationProv = context.read<StationProvider>();
    final auth = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _HomeStationPicker(
            stations: stationProv.allStations,
            onSelect: (station) {
              auth.updateHomeStation(
                stationId: station.locationSignature,
                stationName: station.name,
                latitude: station.latitude,
                longitude: station.longitude,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Home station set to ${station.name}')),
              );
            },
          ),
    );
  }

  void _editDefaultMinutes(BuildContext context, AuthProvider auth) {
    final options = [2, 5, 10, 15];
    showDialog(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Default Alert Time'),
            children:
                options
                    .map(
                      (m) => SimpleDialogOption(
                        onPressed: () {
                          auth.updateDefaultMinutes(m);
                          Navigator.pop(context);
                        },
                        child: Text('$m minutes before arrival'),
                      ),
                    )
                    .toList(),
          ),
    );
  }
}

class _HomeStationPicker extends StatefulWidget {
  final List<Station> stations;
  final void Function(Station) onSelect;

  const _HomeStationPicker({required this.stations, required this.onSelect});

  @override
  State<_HomeStationPicker> createState() => _HomeStationPickerState();
}

class _HomeStationPickerState extends State<_HomeStationPicker> {
  String _query = '';

  List<Station> get _filtered {
    if (_query.isEmpty) return widget.stations.take(50).toList();
    final q = _query.toLowerCase();
    return widget.stations
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.locationSignature.toLowerCase().startsWith(q),
        )
        .take(30)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Home Station',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search station...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final s = _filtered[i];
                return ListTile(
                      leading: const Icon(
                        Icons.train_rounded,
                        color: AppColors.cyan,
                      ),
                      title: Text(s.name),
                      subtitle: Text(
                        s.locationSignature,
                        style: const TextStyle(fontSize: 12),
                      ),
                      dense: true,
                      onTap: () => widget.onSelect(s),
                    )
                    .animate()
                    .fadeIn(
                      duration: 150.ms,
                      delay: Duration(milliseconds: (20 * i).clamp(0, 200)),
                    )
                    .slideX(begin: 0.03, end: 0, duration: 150.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}
