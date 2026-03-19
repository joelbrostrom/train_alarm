import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sov_inte_forbi/theme.dart';

class MilestoneOverlay extends StatelessWidget {
  final int count;
  final VoidCallback onDismiss;

  const MilestoneOverlay({
    super.key,
    required this.count,
    required this.onDismiss,
  });

  String get _title {
    if (count == 1) return 'First safe arrival!';
    if (count == 10) return 'You\'re a pro!';
    if (count == 25) return 'Quarter century!';
    if (count == 50) return 'Legendary commuter!';
    if (count == 100) return 'Hall of fame!';
    return '$count safe arrivals!';
  }

  String get _subtitle {
    if (count == 1) return 'Your first alarm worked perfectly.\nYou\'re in good hands.';
    if (count == 10) return '10 stops, zero missed.\nYou can always count on us.';
    if (count == 25) return '25 safe arrivals and counting.\nYou\'re unstoppable.';
    if (count == 50) return '50 times we\'ve had your back.\nThat\'s dedication.';
    if (count == 100) return '100 safe arrivals!\nYou\'re officially a legend.';
    return 'You\'ve arrived safely $count times.\nNever missed a stop.';
  }

  IconData get _icon {
    if (count >= 100) return Icons.emoji_events_rounded;
    if (count >= 50) return Icons.workspace_premium_rounded;
    if (count >= 25) return Icons.military_tech_rounded;
    if (count >= 10) return Icons.star_rounded;
    return Icons.celebration_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.navySurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.skyBlue],
                ),
              ),
              child: Icon(_icon, size: 40, color: AppColors.navy),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),
            Text(
              _title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            Text(
              _subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.mistDim,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 450.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.cyan,
                fontWeight: FontWeight.w800,
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.5, 0.5)),
            Text(
              'safe arrivals',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mistDim,
                letterSpacing: 1,
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                child: const Text('Awesome!'),
              ),
            ).animate(delay: 800.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
