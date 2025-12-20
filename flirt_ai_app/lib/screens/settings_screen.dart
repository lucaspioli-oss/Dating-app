import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToneSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildToneSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tom Padrão',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: appState.selectedTone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'engraçado', child: Text('😄 Engraçado')),
                    DropdownMenuItem(value: 'ousado', child: Text('🔥 Ousado')),
                    DropdownMenuItem(value: 'romântico', child: Text('❤️ Romântico')),
                    DropdownMenuItem(value: 'casual', child: Text('😎 Casual')),
                    DropdownMenuItem(value: 'confiante', child: Text('💪 Confiante')),
                    DropdownMenuItem(value: 'expert', child: Text('🎯 Expert Mode')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      appState.setSelectedTone(value);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
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
              subtitle: Text(user?.email ?? 'Não logado'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Versão'),
              subtitle: Text(AppConfig.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: const Text('lucaspioli-oss/Dating-app'),
              onTap: () {
                launchUrl(Uri.parse('https://github.com/lucaspioli-oss/Dating-app'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
