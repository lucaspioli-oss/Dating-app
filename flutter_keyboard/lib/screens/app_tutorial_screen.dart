import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';

class AppTutorialScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const AppTutorialScreen({super.key, required this.onComplete});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_TutorialPage> _getPages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _TutorialPage(
        icon: Icons.auto_awesome,
        title: l10n.welcomeTitle,
        subtitle: l10n.welcomeSubtitle,
        description: l10n.welcomeDescription,
        steps: [],
      ),
      _TutorialPage(
        icon: Icons.person_add_alt_1,
        title: l10n.createProfileTitle,
        subtitle: l10n.createProfileSubtitle,
        description: l10n.createProfileDescription,
        steps: [
          _TutorialStep(
            number: '1',
            text: l10n.tutorialStep1,
          ),
          _TutorialStep(
            number: '2',
            text: l10n.tutorialStep2,
          ),
          _TutorialStep(
            number: '3',
            text: l10n.tutorialStep3,
          ),
        ],
      ),
      _TutorialPage(
        icon: Icons.chat_bubble_outline,
        title: l10n.addConversationTitle,
        subtitle: l10n.addConversationSubtitle,
        description: l10n.addConversationDescription,
        steps: [
          _TutorialStep(
            number: '1',
            text: l10n.addConvStep1,
          ),
          _TutorialStep(
            number: '2',
            text: l10n.addConvStep2,
          ),
          _TutorialStep(
            number: '3',
            text: l10n.addConvStep3,
          ),
        ],
      ),
      _TutorialPage(
        icon: Icons.keyboard_alt_outlined,
        title: l10n.useKeyboardTitle,
        subtitle: l10n.useKeyboardSubtitle,
        description: l10n.useKeyboardDescription,
        steps: [
          _TutorialStep(
            number: '1',
            text: l10n.keyboardStep1,
          ),
          _TutorialStep(
            number: '2',
            text: l10n.keyboardStep2,
          ),
          _TutorialStep(
            number: '3',
            text: l10n.keyboardStep3,
          ),
          _TutorialStep(
            number: '4',
            text: l10n.keyboardStep4,
          ),
        ],
        tip: l10n.keyboardTip,
      ),
      _TutorialPage(
        icon: Icons.format_list_numbered,
        title: l10n.multipleMessagesTitle,
        subtitle: l10n.multipleMessagesSubtitle,
        description: l10n.multipleMessagesDescription,
        steps: [
          _TutorialStep(
            number: '1',
            text: l10n.multiMsgStep1,
          ),
          _TutorialStep(
            number: '2',
            text: l10n.multiMsgStep2,
          ),
          _TutorialStep(
            number: '3',
            text: l10n.multiMsgStep3,
          ),
          _TutorialStep(
            number: '4',
            text: l10n.multiMsgStep4,
          ),
        ],
        tip: l10n.multiMsgTip,
      ),
      _TutorialPage(
        icon: Icons.rocket_launch,
        title: l10n.readyTitle,
        subtitle: l10n.readySubtitle,
        description: l10n.readyDescription,
        steps: [],
      ),
    ];
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenAppTutorial', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _completeTutorial,
                  child: Text(l10n.skipButton),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index], index, pages.length);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
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
              child: _buildBottomButtons(context, pages.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_TutorialPage page, int index, int totalPages) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Icon with gradient background
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Steps
          if (page.steps.isNotEmpty) ...[
            const SizedBox(height: 28),
            ...page.steps.map((step) => _buildStepCard(step)),
          ],

          // Tip callout
          if (page.tip != null) ...[
            const SizedBox(height: 16),
            _buildTipCard(page.tip!),
          ],

          // Extra content for specific pages
          if (index == 0) _buildWelcomeExtra(context),
          if (index == totalPages - 1) _buildReadyExtra(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStepCard(_TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevatedDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // Step number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  step.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Text(
                step.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              tip,
              style: TextStyle(
                color: AppColors.warning.withOpacity(0.95),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeExtra(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.primaryMagenta.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildFeatureChip(Icons.smart_toy, l10n.featureAdvancedAI),
                const SizedBox(width: 8),
                _buildFeatureChip(Icons.speed, l10n.featureFastResponses),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFeatureChip(Icons.tune, l10n.featureCustomTones),
                const SizedBox(width: 8),
                _buildFeatureChip(Icons.apps, l10n.featureMultiPlatform),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyExtra(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.readyTip,
                style: TextStyle(
                  color: AppColors.success.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, int totalPages) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == totalPages - 1;
    final isFirstPage = _currentPage == 0;

    if (isLastPage) {
      return GradientButton(
        text: l10n.startUsingButton,
        icon: Icons.rocket_launch,
        onPressed: _completeTutorial,
      );
    }

    if (isFirstPage) {
      return GradientButton(
        text: l10n.letsGoButton,
        icon: Icons.arrow_forward,
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
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

class _TutorialPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<_TutorialStep> steps;
  final String? tip;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.steps,
    this.tip,
  });
}

class _TutorialStep {
  final String number;
  final String text;

  const _TutorialStep({
    required this.number,
    required this.text,
  });
}
