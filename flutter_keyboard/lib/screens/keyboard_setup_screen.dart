import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/keyboard_service.dart';
import '../config/app_theme.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';

class KeyboardSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const KeyboardSetupScreen({super.key, required this.onComplete});

  @override
  State<KeyboardSetupScreen> createState() => _KeyboardSetupScreenState();
}

class _KeyboardSetupScreenState extends State<KeyboardSetupScreen> {
  final PageController _pageController = PageController();
  final KeyboardService _keyboardService = KeyboardService();
  int _currentPage = 0;
  bool _isKeyboardEnabled = false;

  List<_SetupStep> _getSteps(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _SetupStep(
        icon: Icons.keyboard_alt_outlined,
        title: l10n.activateKeyboardTitle,
        description: l10n.activateKeyboardDesc,
        instruction: l10n.activateKeyboardInstruction,
      ),
      _SetupStep(
        icon: Icons.security_outlined,
        title: l10n.fullAccessTitle,
        description: l10n.fullAccessDesc,
        instruction: l10n.fullAccessInstruction,
        tip: l10n.fullAccessTip,
      ),
      _SetupStep(
        icon: Icons.swap_horiz,
        title: l10n.switchKeyboardTitle,
        description: l10n.switchKeyboardDesc,
        instruction: l10n.switchKeyboardInstruction,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _checkKeyboardStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkKeyboardStatus() async {
    final enabled = await _keyboardService.isKeyboardEnabled();
    if (mounted) {
      setState(() => _isKeyboardEnabled = enabled);
    }
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenKeyboardSetup', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _getSteps(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeSetup,
                child: Text(l10n.skipButton),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (index == 0) _checkKeyboardStatus();
                },
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return _buildStepPage(steps[index], index);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildBottomButtons(context, steps.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPage(_SetupStep step, int index) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Instruction card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.elevatedDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.instruction,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Security tip (only when present)
          if (step.tip != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.tip!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Keyboard status indicator (only on first page)
          if (index == 0) ...[
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isKeyboardEnabled
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isKeyboardEnabled
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: _isKeyboardEnabled
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isKeyboardEnabled
                        ? l10n.keyboardEnabledStatus
                        : l10n.keyboardNotEnabledStatus,
                    style: TextStyle(
                      color: _isKeyboardEnabled
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, int totalSteps) {
    final l10n = AppLocalizations.of(context)!;

    if (_currentPage == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientButton(
            text: l10n.openSettingsButton,
            icon: Icons.settings,
            onPressed: () async {
              await _keyboardService.openKeyboardSettings();
              // Re-check after returning from settings
              Future.delayed(const Duration(seconds: 1), _checkKeyboardStatus);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Text(l10n.nextButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _completeSetup,
            child: Text(
              l10n.continueWithoutKeyboard,
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ],
      );
    }

    if (_currentPage == totalSteps - 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientButton(
            text: l10n.startUsingButton,
            icon: Icons.rocket_launch,
            onPressed: _completeSetup,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Text(l10n.backButton),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Text(l10n.nextButton),
          ),
        ),
      ],
    );
  }
}

class _SetupStep {
  final IconData icon;
  final String title;
  final String description;
  final String instruction;
  final String? tip;

  const _SetupStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.instruction,
    this.tip,
  });
}
