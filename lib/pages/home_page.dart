import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/location_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/theme.dart';
import 'package:sov_inte_forbi/widgets/alarm_card.dart';
import 'package:sov_inte_forbi/widgets/nav_shell.dart';
import 'package:sov_inte_forbi/widgets/station_search.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final alarms = context.watch<AlarmProvider>();
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 800;

    return CustomScrollView(
      slivers: [
        if (!isWide)
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Icon(Icons.train_rounded, color: AppColors.cyan, size: 24),
                const SizedBox(width: 8),
                const Text('Sov Inte Förbi'),
              ],
            ),
            actions: [
              if (!auth.isSignedIn)
                TextButton.icon(
                  onPressed: () => auth.signInWithGoogle(),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign in'),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.cyan,
                    backgroundImage:
                        auth.user?.photoUrl != null
                            ? NetworkImage(auth.user!.photoUrl!)
                            : null,
                    child:
                        auth.user?.photoUrl == null
                            ? Text(
                              auth.user?.displayName.isNotEmpty == true
                                  ? auth.user!.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                            : null,
                  ),
                ),
            ],
          ),
        SliverToBoxAdapter(child: _HeroBanner()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                if (alarms.activeAlarms.isNotEmpty) ...[
                  Text(
                    'Active Alarms',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...alarms.activeAlarms.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AlarmCard(alarm: a),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _NearbyStationSuggestion(),
                _CommuteShortcuts(),
                if (alarms.dismissCount > 0) ...[
                  _TripCounter(count: alarms.dismissCount),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _QuickActions(),
                const SizedBox(height: 24),
                _RecentDestinations(),
                _ReviewPrompt(dismissCount: alarms.dismissCount),
                _ReferralPrompt(dismissCount: alarms.dismissCount),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF0A1628), Color(0xFF071020)],
        ),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                'Never miss\nyour stop again.',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 32, height: 1.2),
              )
              .animate()
              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
              .slideY(begin: 0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 12),
          Text(
                'Set an alarm for your destination station.\nWe\'ll wake you before your stop.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mistDim,
                  height: 1.5,
                ),
              )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.15, end: 0, duration: 500.ms),
          const SizedBox(height: 24),
          Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openCreateAlarm(context),
                    icon: const Icon(Icons.alarm_add_rounded),
                    label: const Text('Create Alarm'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => NavShell.switchTab(context, 1),
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Open Map'),
                  ),
                ],
              )
              .animate(delay: 400.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.15, end: 0, duration: 500.ms),
        ],
      ),
    );
  }

  void _openCreateAlarm(BuildContext context) {
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
            child: const StationSearch(),
          ),
    );
  }
}

// --- Nearby Station Suggestion (P2) ---

class _NearbyStationSuggestion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final stations = context.watch<StationProvider>();
    final alarms = context.watch<AlarmProvider>();

    if (!location.hasPermission || location.currentPosition == null) {
      return const SizedBox.shrink();
    }
    if (alarms.activeAlarms.isNotEmpty) return const SizedBox.shrink();

    final pos = location.currentPosition!;
    final nearby = stations.nearbyStations(
      pos.latitude,
      pos.longitude,
      limit: 1,
    );
    if (nearby.isEmpty) return const SizedBox.shrink();

    final station = nearby.first;
    final distKm = StationProvider.quickDistanceKm(
      pos.latitude,
      pos.longitude,
      station.latitude,
      station.longitude,
    );

    if (distKm > 50) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.cyan.withValues(alpha: 0.08),
              AppColors.navySurface,
            ],
          ),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.near_me_rounded,
                color: AppColors.cyan,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Near ${station.name}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.white),
                  ),
                  Text(
                    '${distKm.toStringAsFixed(1)} km away',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
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
                          ChangeNotifierProvider.value(
                            value: context.read<AuthProvider>(),
                          ),
                        ],
                        child: StationSearch(preselectedStation: station),
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text('Set Alarm'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

// --- Commute Shortcuts (P2) ---

class _CommuteShortcuts extends StatefulWidget {
  @override
  State<_CommuteShortcuts> createState() => _CommuteShortcutsState();
}

class _CommuteShortcutsState extends State<_CommuteShortcuts> {
  List<dynamic>? _commutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stations = context.read<StationProvider>();
    final result = await stations.getCommuteStations();
    if (mounted && result.isNotEmpty) {
      setState(() => _commutes = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_commutes == null || _commutes!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Commutes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _commutes!.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final station = _commutes![index];
              return Material(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    final alarms = context.read<AlarmProvider>();
                    final auth = context.read<AuthProvider>();
                    alarms.createAlarmFromStation(
                      stationId: station.locationSignature,
                      stationName: station.name,
                      latitude: station.latitude,
                      longitude: station.longitude,
                      alertMinutes: auth.user?.defaultAlertMinutes ?? 5,
                      userId: auth.isSignedIn ? auth.user!.uid : null,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              color: AppColors.cyan,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text('${station.name} — alarm active, sleep easy'),
                          ],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          size: 18,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          station.name,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(
                duration: 200.ms,
                delay: Duration(milliseconds: (50 * index).clamp(0, 200)),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// --- Trip Counter (P2) ---

class _TripCounter extends StatelessWidget {
  final int count;

  const _TripCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.06),
            AppColors.navySurface.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe arrivals',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppColors.white),
                ),
                Text(
                  count == 1
                      ? 'Your first one! Many more to come.'
                      : 'You\'ve never missed a stop.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.shield_rounded, color: AppColors.cyan, size: 28),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// --- Quick Actions ---

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final alarms = context.read<AlarmProvider>();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionChip(
          icon: Icons.alarm_add_rounded,
          label: 'New Alarm',
          color: AppColors.cyan,
          onTap:
              () => showModalBottomSheet(
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
                        ChangeNotifierProvider.value(
                          value: context.read<AuthProvider>(),
                        ),
                      ],
                      child: const StationSearch(),
                    ),
              ),
        ),
        if (auth.isSignedIn && auth.user?.homeStationId != null)
          _ActionChip(
            icon: Icons.home_rounded,
            label: 'Go Home',
            color: AppColors.skyBlue,
            onTap: () {
              final user = auth.user!;
              final alarm = alarms.createAlarmFromStation(
                stationId: user.homeStationId!,
                stationName: user.homeStationName ?? 'Home',
                latitude: user.homeLatitude ?? 0,
                longitude: user.homeLongitude ?? 0,
                alertMinutes: user.defaultAlertMinutes,
                userId: user.uid,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: AppColors.cyan,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${user.homeStationName ?? "Home"} — alarm active, sleep easy',
                      ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => alarms.cancelAlarm(alarm.id),
                  ),
                ),
              );
            },
          ),
        _ActionChip(
          icon: Icons.volume_up_rounded,
          label: 'Test Sound',
          color: AppColors.amber,
          onTap: () => alarms.testAlarmSound(),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Recent Destinations ---

class _RecentDestinations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationProvider>();

    if (stations.recentStations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Destinations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stations.recentStations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final station = stations.recentStations[index];
              return Material(
                    color: AppColors.navySurface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
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
                                  ChangeNotifierProvider.value(
                                    value: context.read<AuthProvider>(),
                                  ),
                                ],
                                child: StationSearch(
                                  preselectedStation: station,
                                ),
                              ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.train_rounded,
                              size: 18,
                              color: AppColors.skyBlue,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              station.name,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              station.locationSignature,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 200.ms,
                    delay: Duration(milliseconds: (50 * index).clamp(0, 300)),
                  )
                  .slideX(begin: 0.05, end: 0, duration: 200.ms);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// --- Review Prompt (P3 — after 3rd dismissal) ---

class _ReviewPrompt extends StatefulWidget {
  final int dismissCount;

  const _ReviewPrompt({required this.dismissCount});

  @override
  State<_ReviewPrompt> createState() => _ReviewPromptState();
}

class _ReviewPromptState extends State<_ReviewPrompt> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.dismissCount < 3 || widget.dismissCount > 8) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.navySurface,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.amber, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enjoying Sov Inte Förbi?',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.white),
                  ),
                  Text(
                    'A review helps other commuters find us.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _dismissed = true),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.mistDim,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// --- Referral Prompt (P3 — after 5th dismissal) ---

class _ReferralPrompt extends StatefulWidget {
  final int dismissCount;

  const _ReferralPrompt({required this.dismissCount});

  @override
  State<_ReferralPrompt> createState() => _ReferralPromptState();
}

class _ReferralPromptState extends State<_ReferralPrompt> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || widget.dismissCount < 5) {
      return const SizedBox.shrink();
    }
    // Only show occasionally — not every session
    if (widget.dismissCount > 5 && widget.dismissCount % 10 != 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.skyBlue.withValues(alpha: 0.08),
              AppColors.navySurface,
            ],
          ),
          border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppColors.skyBlue, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Know someone who falls asleep on trains?',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You\'ve arrived safely ${widget.dismissCount} times. Share the app!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                final uri = Uri.parse('https://sovintegorbi.web.app');
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              color: AppColors.skyBlue,
            ),
            IconButton(
              onPressed: () => setState(() => _dismissed = true),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.mistDim,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}
