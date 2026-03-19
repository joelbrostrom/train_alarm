import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/theme.dart';

class AlarmTriggerOverlay extends StatelessWidget {
  final Alarm alarm;

  const AlarmTriggerOverlay({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    final alarms = context.read<AlarmProvider>();

    return Material(
      color: Colors.black87,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppColors.coral.withValues(alpha: 0.2), Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing ring
                  _PulsingRing()
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(0.9, 0.9),
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 40),

                  Text(
                        'YOUR STOP IS NEAR',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.coral,
                          letterSpacing: 3,
                          fontSize: 14,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(duration: 500.ms)
                      .then()
                      .fadeOut(duration: 500.ms),
                  const SizedBox(height: 16),

                  Text(
                    alarm.stationName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 36,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),

                  Text(
                    'Get ready to exit the train',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mist,
                      fontSize: 18,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                  if (alarm.currentDistanceMeters != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _formatDistance(alarm.currentDistanceMeters!),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                    Text(
                      'remaining',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mistDim,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Dismiss button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => alarms.dismissAlarm(alarm.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('I\'M AWAKE'),
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 12),

                  // Snooze button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => alarms.snoozeAlarm(alarm.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mist,
                        side: const BorderSide(color: AppColors.mistDim),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Snooze 30 seconds'),
                    ),
                  ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _PulsingRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
          ),
          // Inner circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.coral,
              boxShadow: [
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
