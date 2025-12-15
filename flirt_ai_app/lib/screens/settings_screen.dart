import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTestingConnection = false;
  bool? _connectionStatus;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _urlController.text = appState.backendUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final apiService = ApiService(baseUrl: _urlController.text);
      final isOnline = await apiService.checkHealth();

      setState(() {
        _connectionStatus = isOnline;
      });

      if (isOnline) {
        _showMessage('Conexão bem-sucedida!', Colors.green);
      } else {
        _showMessage('Backend offline ou inacessível', Colors.red);
      }
    } catch (e) {
      setState(() {
        _connectionStatus = false;
      });
      _showMessage('Erro: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  void _saveSettings() {
    final appState = context.read<AppState>();
    appState.setBackendUrl(_urlController.text);
    _showMessage('Configurações salvas!', Colors.green);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBackendSection(),
          const SizedBox(height: 24),
          _buildToneSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildBackendSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend API',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL do Backend',
                hintText: 'http://localhost:3000',
                border: const OutlineInputBorder(),
                suffixIcon: _connectionStatus == null
                    ? null
                    : Icon(
                        _connectionStatus! ? Icons.check_circle : Icons.error,
                        color: _connectionStatus! ? Colors.green : Colors.red,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTestingConnection ? null : _testConnection,
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(
                      _isTestingConnection ? 'Testando...' : 'Testar Conexão',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure a URL do seu backend Node.js',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneSection() {
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

  Widget _buildAboutSection() {
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
              leading: const Icon(Icons.info_outline),
              title: const Text('Versão'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              subtitle: const Text('lucaspioli-oss/Dating-app'),
              onTap: () {
                launchUrl(Uri.parse('https://github.com/lucaspioli-oss/Dating-app'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Documentação'),
              onTap: () {
                launchUrl(Uri.parse('https://github.com/lucaspioli-oss/Dating-app#readme'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
