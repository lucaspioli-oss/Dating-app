import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/subscription_service.dart';
import '../services/keyboard_service.dart';
import 'training_feedback_screen.dart';
import 'keyboard_setup_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracoes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToneSection(context),
          const SizedBox(height: 24),
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

  Widget _buildToneSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modo de Analise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expert Mode',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calibragem automatica baseada em principios de atracao',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teclado Inteligente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _isKeyboardEnabled
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: _isKeyboardEnabled ? Colors.green : Colors.orange,
              ),
              title: const Text('Status do Teclado'),
              subtitle: Text(
                _isKeyboardEnabled ? 'Ativado' : 'Desativado',
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
                      child: const Text('Ativar'),
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Ver guia de ativacao'),
              subtitle: Text(
                _isKeyboardEnabled
                    ? 'Reveja os passos para configurar o teclado'
                    : 'Siga o passo a passo para ativar o teclado',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Treinamento da IA',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEV',
                    style: TextStyle(
                      color: Colors.white,
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
              title: const Text('Instrucoes de Treinamento'),
              subtitle: const Text('Personalize como a IA responde'),
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
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sobre',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Logado como'),
              subtitle: Text(user?.email ?? 'Nao logado'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Versao'),
              subtitle: Text(AppConfig.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Politica de Privacidade'),
              onTap: () {
                launchUrl(Uri.parse('https://desenrola-ia.web.app/privacy'));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair da conta', style: TextStyle(color: Colors.red)),
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await KeyboardService().clearKeyboardAuth();
              await FirebaseAuth.instance.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
