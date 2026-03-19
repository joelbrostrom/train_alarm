import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/providers/alarm_provider.dart';
import 'package:sov_inte_forbi/theme.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;

  const AlarmCard({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    final alarms = context.read<AlarmProvider>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_statusColor.withValues(alpha: 0.15), AppColors.navySurface],
        ),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(alarm: alarm),
                const Spacer(),
                if (alarm.isLive)
                  IconButton(
                    onPressed: () => alarms.cancelAlarm(alarm.id),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Cancel alarm',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.mistDim,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.train_rounded, color: _statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alarm.nickname ?? alarm.stationName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Alert ${alarm.alertMinutesBefore} min before arrival',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (alarm.currentDistanceMeters != null) ...[
              const SizedBox(height: 12),
              _DistanceIndicator(alarm: alarm),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Color get _statusColor {
    switch (alarm.status) {
      case AlarmStatus.active:
      case AlarmStatus.tracking:
        return AppColors.cyan;
      case AlarmStatus.approaching:
        return AppColors.amber;
      case AlarmStatus.triggered:
        return AppColors.coral;
      case AlarmStatus.snoozed:
        return AppColors.amber;
      case AlarmStatus.dismissed:
      case AlarmStatus.completed:
        return AppColors.mistDim;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final Alarm alarm;

  const _StatusBadge({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(alarm.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alarm.isLive)
            Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 800.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.5, 1.5),
                  end: const Offset(1, 1),
                  duration: 800.ms,
                ),
          Text(
            alarm.statusLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForStatus(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.active:
      case AlarmStatus.tracking:
        return AppColors.cyan;
      case AlarmStatus.approaching:
        return AppColors.amber;
      case AlarmStatus.triggered:
        return AppColors.coral;
      case AlarmStatus.snoozed:
        return AppColors.amber;
      case AlarmStatus.dismissed:
      case AlarmStatus.completed:
        return AppColors.mistDim;
    }
  }
}

class _DistanceIndicator extends StatelessWidget {
  final Alarm alarm;

  const _DistanceIndicator({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final distKm = (alarm.currentDistanceMeters ?? 0) / 1000;
    final eta = alarm.estimatedMinutesAway;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                distKm < 1
                    ? '${alarm.currentDistanceMeters?.toStringAsFixed(0)} m'
                    : '${distKm.toStringAsFixed(1)} km',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'distance',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        if (eta != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eta < 1 ? '< 1 min' : '~${eta.toStringAsFixed(0)} min',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        eta <= alarm.alertMinutesBefore
                            ? AppColors.coral
                            : AppColors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'est. arrival',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
