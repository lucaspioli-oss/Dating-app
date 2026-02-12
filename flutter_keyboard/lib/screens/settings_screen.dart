import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../services/subscription_service.dart';
import '../services/keyboard_service.dart';
import '../services/firebase_auth_service.dart';
import 'training_feedback_screen.dart';
import 'keyboard_setup_screen.dart';
import 'app_tutorial_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final KeyboardService _keyboardService = KeyboardService();
  bool _isDeveloper = false;
  bool _isKeyboardEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final isDev = await _subscriptionService.isDeveloper();
    final isKeyboard = await _keyboardService.isKeyboardEnabled();
    if (mounted) {
      setState(() {
        _isDeveloper = isDev;
        _isKeyboardEnabled = isKeyboard;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildKeyboardSection(context),
          if (_isDeveloper) ...[
            const SizedBox(height: 24),
            _buildTrainingSection(context),
          ],
          const SizedBox(height: 24),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildKeyboardSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.smartKeyboardSection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _isKeyboardEnabled
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: _isKeyboardEnabled ? AppColors.success : AppColors.warning,
              ),
              title: Text(l10n.keyboardStatusLabel),
              subtitle: Text(
                _isKeyboardEnabled ? l10n.keyboardStatusActive : l10n.keyboardStatusInactive,
              ),
              trailing: _isKeyboardEnabled
                  ? null
                  : TextButton(
                      onPressed: () async {
                        await _keyboardService.openKeyboardSettings();
                        Future.delayed(
                          const Duration(seconds: 1),
                          () async {
                            final enabled =
                                await _keyboardService.isKeyboardEnabled();
                            if (mounted) {
                              setState(() => _isKeyboardEnabled = enabled);
                            }
                          },
                        );
                      },
                      child: Text(l10n.activateButton),
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(l10n.viewActivationGuideTitle),
              subtitle: Text(
                _isKeyboardEnabled
                    ? l10n.viewActivationGuideDesc
                    : l10n.followStepsToActivate,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenKeyboardSetup', false);
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KeyboardSetupScreen(
                        onComplete: () {
                          Navigator.of(context).pop();
                          _loadStatus();
                        },
                      ),
                    ),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(l10n.viewAppTutorialTitle),
              subtitle: Text(
                l10n.viewAppTutorialDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AppTutorialScreen(
                      onComplete: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.aiTrainingSection,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.devBadge,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: Text(l10n.trainingInstructionsTitle),
              subtitle: Text(l10n.trainingInstructionsDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TrainingFeedbackScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aboutSection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.loggedAsLabel),
              subtitle: Text(user?.email ?? l10n.notLoggedInLabel),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.versionLabel),
              subtitle: Text(AppConfig.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.privacyPolicyLabel),
              onTap: () {
                launchUrl(Uri.parse('https://desenrola-ia.web.app/privacy'));
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text(l10n.logoutLabel, style: TextStyle(color: AppColors.error)),
              onTap: () => _showLogoutDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(l10n.deleteAccountLabel, style: TextStyle(color: AppColors.error)),
              subtitle: Text(l10n.deleteAccountDesc),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(
          l10n.deleteAccountConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await KeyboardService().clearKeyboardAuth();
                await FirebaseAuthService().deleteAccount();
                if (mounted) {
                  AppSnackBar.success(context, l10n.accountDeletedSuccess);
                }
              } catch (e) {
                if (mounted) {
                  AppSnackBar.error(context, '${l10n.accountDeleteError} $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deletePermanentlyButton),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await KeyboardService().clearKeyboardAuth();
              await FirebaseAuth.instance.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );
  }
}
