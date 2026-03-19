import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/firebase_options.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/providers/location_provider.dart';
import 'package:sov_inte_forbi/providers/station_provider.dart';
import 'package:sov_inte_forbi/services/alarm_engine.dart';
import 'package:sov_inte_forbi/services/audio_service.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';
import 'package:sov_inte_forbi/services/location_service.dart';
import 'package:sov_inte_forbi/services/trafikverket_service.dart';
import 'package:sov_inte_forbi/theme.dart';
import 'package:sov_inte_forbi/widgets/alarm_trigger_overlay.dart';
import 'package:sov_inte_forbi/widgets/nav_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WakeMyStopApp());
}

final _firestoreService = FirestoreService();
final _trafikverketService = TrafikverketService();
final _locationService = LocationService();
final _audioService = AudioService();
final _alarmEngine = AlarmEngine(_locationService);

class WakeMyStopApp extends StatelessWidget {
  const WakeMyStopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(_firestoreService)),
        ChangeNotifierProvider(
          create:
              (_) => StationProvider(_trafikverketService, _firestoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(_locationService),
        ),
        ChangeNotifierProvider(
          create:
              (_) =>
                  AlarmProvider(_firestoreService, _alarmEngine, _audioService),
        ),
      ],
      child: MaterialApp(
        title: 'Sov Inte Förbi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final stationProv = context.read<StationProvider>();
    final locationProv = context.read<LocationProvider>();

    await Future.wait([stationProv.loadStations(), locationProv.initialize()]);

    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final alarmProv = context.watch<AlarmProvider>();

    if (auth.isSignedIn && _initialized && _lastSyncedUid != auth.user!.uid) {
      final uid = auth.user!.uid;
      final name = auth.user!.displayName;
      final wasNull = _lastSyncedUid == null;
      _lastSyncedUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stationProv = context.read<StationProvider>();
        final alarmProv = context.read<AlarmProvider>();
        stationProv.loadFavorites(uid);
        stationProv.loadRecentStations(uid);
        alarmProv.loadAlarms(uid);
        if (wasNull) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                name.isNotEmpty ? 'Welcome, $name!' : 'Signed in successfully!',
              ),
            ),
          );
        }
      });
    } else if (!auth.isSignedIn) {
      _lastSyncedUid = null;
    }

    if (!_initialized) {
      return const _SplashScreen();
    }

    return Stack(
      children: [
        const NavShell(),
        if (alarmProv.alarmTriggered && alarmProv.triggeredAlarm != null)
          AlarmTriggerOverlay(alarm: alarmProv.triggeredAlarm!),
      ],
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.train_rounded, size: 64, color: AppColors.cyan)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                ),
            const SizedBox(height: 24),
            Text(
              'Sov Inte Förbi',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Loading stations...',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.cyan,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
