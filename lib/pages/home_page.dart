import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/theme.dart';
import 'package:sov_inte_forbi/widgets/alarm_card.dart';
import 'package:sov_inte_forbi/widgets/station_search.dart';

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
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _QuickActions(),
                const SizedBox(height: 24),
                _RecentDestinations(),
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
                    onPressed: () {
                      // Navigate to map - handled by NavShell
                    },
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
              alarms.createAlarmFromStation(
                stationId: user.homeStationId!,
                stationName: user.homeStationName ?? 'Home',
                latitude: user.homeLatitude ?? 0,
                longitude: user.homeLongitude ?? 0,
                alertMinutes: user.defaultAlertMinutes,
                userId: user.uid,
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

class _RecentDestinations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stations = context.watch<StationProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isSignedIn || stations.recentStations.isEmpty) {
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
      ],
    );
  }
}
