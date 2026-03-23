import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../config/app_haptics.dart';
import '../providers/app_state.dart';
import '../services/subscription_service.dart';
import '../services/keyboard_service.dart';
import '../services/firebase_auth_service.dart';
import 'training_feedback_screen.dart';
import 'keyboard_setup_screen.dart';
import 'app_tutorial_screen.dart';
import 'templates_screen.dart';
import 'profile_screen.dart' show SubscriptionContent;

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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSubscriptionSection(context),
          const SizedBox(height: 16),
          _buildKeyboardSection(context),
          const SizedBox(height: 16),
          _buildToolsSection(context),
          if (_isDeveloper) ...[
            const SizedBox(height: 16),
            _buildTrainingSection(context),
          ],
          const SizedBox(height: 16),
          _buildLanguageSection(context),
          const SizedBox(height: 16),
          _buildAboutSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.elevatedDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.elevatedDark, height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap != null ? () {
        AppHaptics.lightImpact();
        onTap();
      } : null,
      borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.elevatedDark, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    return _buildSectionContainer(
      title: 'Assinatura',
      icon: Icons.credit_card_outlined,
      children: [
        _buildSettingsRow(
          icon: Icons.workspace_premium_outlined,
          title: 'Gerenciar assinatura',
          subtitle: 'Veja seu plano, renove ou cancele',
          isLast: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionContent()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyboardSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionContainer(
      title: l10n.smartKeyboardSection,
      icon: Icons.keyboard_alt_outlined,
      children: [
        _buildSettingsRow(
          icon: _isKeyboardEnabled ? Icons.check_circle : Icons.warning_amber_rounded,
          iconColor: _isKeyboardEnabled ? AppColors.success : AppColors.warning,
          title: l10n.keyboardStatusLabel,
          subtitle: _isKeyboardEnabled ? l10n.keyboardStatusActive : l10n.keyboardStatusInactive,
          trailing: _isKeyboardEnabled
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.activateButton,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
          onTap: _isKeyboardEnabled ? null : () async {
            await _keyboardService.openKeyboardSettings();
            Future.delayed(
              const Duration(seconds: 1),
              () async {
                final enabled = await _keyboardService.isKeyboardEnabled();
                if (mounted) {
                  setState(() => _isKeyboardEnabled = enabled);
                }
              },
            );
          },
        ),
        _buildSettingsRow(
          icon: Icons.school_outlined,
          title: l10n.viewActivationGuideTitle,
          subtitle: _isKeyboardEnabled ? l10n.viewActivationGuideDesc : l10n.followStepsToActivate,
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
        _buildSettingsRow(
          icon: Icons.auto_awesome,
          title: l10n.viewAppTutorialTitle,
          subtitle: l10n.viewAppTutorialDesc,
          isLast: true,
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
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return _buildSectionContainer(
      title: 'Ferramentas',
      icon: Icons.build_outlined,
      children: [
        _buildSettingsRow(
          icon: Icons.menu_book_outlined,
          title: 'Roteiros de Conversa',
          subtitle: 'Scripts prontos para diferentes situacoes',
          isLast: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemplatesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrainingSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionContainer(
      title: l10n.aiTrainingSection,
      icon: Icons.psychology,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.devBadge,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildSettingsRow(
          icon: Icons.psychology,
          title: l10n.trainingInstructionsTitle,
          subtitle: l10n.trainingInstructionsDesc,
          isLast: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TrainingFeedbackScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Espanol';
      default: return 'Portugues';
    }
  }

  String _languageFlag(String code) {
    switch (code) {
      case 'en': return '🇺🇸';
      case 'es': return '🇪🇸';
      default: return '🇧🇷';
    }
  }

  Widget _buildLanguageSection(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentLang = appState.locale.languageCode;

    return _buildSectionContainer(
      title: 'Idioma / Language',
      icon: Icons.language,
      children: [
        _buildSettingsRow(
          icon: Icons.language,
          title: '${_languageFlag(currentLang)} ${_languageLabel(currentLang)}',
          isLast: true,
          onTap: () {
            _showLanguageDialog(context, appState, currentLang);
          },
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, AppState appState, String currentLang) {
    final languages = [
      {'code': 'pt', 'flag': '🇧🇷', 'name': 'Portugues'},
      {'code': 'en', 'flag': '🇺🇸', 'name': 'English'},
      {'code': 'es', 'flag': '🇪🇸', 'name': 'Espanol'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Idioma / Language', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = currentLang == lang['code'];
            return ListTile(
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(
                lang['name']!,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryCoral : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primaryCoral)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                appState.setLocale(Locale(lang['code']!));
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;

    return _buildSectionContainer(
      title: l10n.aboutSection,
      icon: Icons.info_outline,
      children: [
        _buildSettingsRow(
          icon: Icons.person_outline,
          title: l10n.loggedAsLabel,
          subtitle: user?.email ?? l10n.notLoggedInLabel,
        ),
        _buildSettingsRow(
          icon: Icons.info_outline,
          title: l10n.versionLabel,
          subtitle: AppConfig.appVersion,
        ),
        _buildSettingsRow(
          icon: Icons.privacy_tip_outlined,
          title: l10n.privacyPolicyLabel,
          onTap: () {
            launchUrl(Uri.parse('https://desenrola-ia.web.app/privacy'));
          },
        ),
        _buildSettingsRow(
          icon: Icons.logout,
          iconColor: AppColors.error,
          title: l10n.logoutLabel,
          titleColor: AppColors.error,
          onTap: () => _showLogoutDialog(context),
        ),
        _buildSettingsRow(
          icon: Icons.delete_forever,
          iconColor: AppColors.error,
          title: l10n.deleteAccountLabel,
          titleColor: AppColors.error,
          subtitle: l10n.deleteAccountDesc,
          isLast: true,
          onTap: () => _showDeleteAccountDialog(context),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteAccountTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.deleteAccountConfirmation, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.textSecondary)),
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
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logoutTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.logoutConfirmation, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await KeyboardService().clearKeyboardAuth();
              await Supabase.instance.client.auth.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );
  }
}
