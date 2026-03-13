import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/freemium_service.dart';

/// Bottom sheet shown when the user exhausts their free daily AI suggestions.
///
/// Usage:
/// ```dart
/// FreemiumUpgradePrompt.show(context);
/// ```
class FreemiumUpgradePrompt extends StatefulWidget {
  const FreemiumUpgradePrompt({super.key});

  /// Convenience method to display the upgrade prompt as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FreemiumUpgradePrompt(),
    );
  }

  @override
  State<FreemiumUpgradePrompt> createState() => _FreemiumUpgradePromptState();
}

class _FreemiumUpgradePromptState extends State<FreemiumUpgradePrompt> {
  late Timer _timer;
  Duration _timeUntilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilReset();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeUntilReset();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeUntilReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      _timeUntilReset = midnight.difference(now);
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _navigateToSubscription() {
    Navigator.of(context).pop(); // close sheet
    // Navigate to subscription tab (index 2 in the main PageView)
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (route) => false,
      arguments: {'tab': 2},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Limite diario atingido',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Voce usou todas as ${FreemiumService.maxFreeUsesPerDay} sugestoes gratis de hoje.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),

          // Countdown card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.elevatedDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Novas sugestoes em ${_formatDuration(_timeUntilReset)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subscribe button
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: 'Assinar para ilimitado',
              icon: Icons.star_rounded,
              onPressed: _navigateToSubscription,
            ),
          ),
          const SizedBox(height: 12),

          // Back button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Voltar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
