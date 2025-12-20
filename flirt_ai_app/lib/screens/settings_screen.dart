import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTestingConnection = false;
  bool? _connectionStatus;
  bool _useLocalBackend = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _urlController.text = appState.backendUrl;
    _useLocalBackend = appState.backendUrl == AppConfig.developmentBackendUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _isDeveloper {
    final user = FirebaseAuth.instance.currentUser;
    return AppConfig.isDeveloper(user?.email);
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

  void _toggleBackendMode(bool useLocal) {
    setState(() {
      _useLocalBackend = useLocal;
      _urlController.text = useLocal
          ? AppConfig.developmentBackendUrl
          : AppConfig.productionBackendUrl;
      _connectionStatus = null;
    });
    _saveSettings();
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
          // Seção de desenvolvedor (só aparece para devs)
          if (_isDeveloper) ...[
            _buildDeveloperSection(),
            const SizedBox(height: 24),
          ],
          _buildBackendSection(),
          const SizedBox(height: 24),
          _buildToneSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_mode, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Modo Desenvolvedor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Você está logado como desenvolvedor. Escolha onde rodar o backend:',
              style: TextStyle(color: Colors.amber.shade900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBackendOption(
                    icon: Icons.cloud,
                    label: 'Railway',
                    subtitle: 'Produção',
                    isSelected: !_useLocalBackend,
                    onTap: () => _toggleBackendMode(false),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBackendOption(
                    icon: Icons.computer,
                    label: 'Local',
                    subtitle: 'localhost:3000',
                    isSelected: _useLocalBackend,
                    onTap: () => _toggleBackendMode(true),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _useLocalBackend ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _useLocalBackend ? Icons.computer : Icons.cloud,
                    size: 20,
                    color: _useLocalBackend ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _useLocalBackend
                          ? 'Usando backend LOCAL - rode: npm run dev'
                          : 'Usando Railway (produção)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _useLocalBackend ? Colors.green.shade700 : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendSection() {
    // Para desenvolvedores, essa seção é mais compacta
    if (_isDeveloper) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'URL Personalizada',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'URL customizada (opcional)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _connectionStatus == null
                      ? null
                      : Icon(
                          _connectionStatus! ? Icons.check_circle : Icons.error,
                          color: _connectionStatus! ? Colors.green : Colors.red,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _isTestingConnection ? null : _testConnection,
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find, size: 18),
                    label: const Text('Testar'),
                  ),
                  TextButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Para usuários normais, não mostra nada (Railway é fixo)
    return const SizedBox.shrink();
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

  Widget _buildAboutSection() {
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
            if (_isDeveloper)
              ListTile(
                leading: Icon(Icons.verified, color: Colors.amber.shade700),
                title: const Text('Status'),
                subtitle: Text(
                  'Desenvolvedor',
                  style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold),
                ),
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
