import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/theme.dart';
import 'package:sov_inte_forbi/widgets/station_search.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stations = context.watch<StationProvider>();
    final isWide = MediaQuery.of(context).size.width > 800;

    final favorites = stations.favoriteStations;

    return CustomScrollView(
      slivers: [
        if (!isWide)
          const SliverAppBar(floating: true, title: Text('Favorites')),
        if (favorites.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_border_rounded,
                      size: 64,
                      color: AppColors.mistDim,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorite stations yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search for a station and tap the star to add it.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (!auth.isSignedIn) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Sign in to sync favorites across devices.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mistDim,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => auth.signInWithGoogle(),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign in to sync'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == favorites.length) {
                  if (!auth.isSignedIn) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 16,
                            color: AppColors.mistDim,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saved locally.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: () => auth.signInWithGoogle(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: const Text('Sign in to sync'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final fav = favorites[index];
                return Animate(
                  effects: [
                    FadeEffect(
                      duration: 300.ms,
                      delay: Duration(milliseconds: (50 * index).clamp(0, 400)),
                    ),
                    SlideEffect(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                      duration: 300.ms,
                    ),
                  ],
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(
                        Icons.star_rounded,
                        color: AppColors.amber,
                      ),
                      title: Text(fav.name),
                      subtitle: Text(fav.locationSignature),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              _openAlarmSheet(context, fav);
                            },
                            icon: const Icon(
                              Icons.alarm_add_rounded,
                              color: AppColors.cyan,
                            ),
                            tooltip: 'Set alarm',
                          ),
                          IconButton(
                            onPressed:
                                () => stations.toggleFavorite(
                                  fav,
                                  auth.isSignedIn ? auth.user!.uid : null,
                                ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.coral,
                            ),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: favorites.length + 1),
            ),
          ),
      ],
    );
  }

  void _openAlarmSheet(BuildContext context, station) {
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
