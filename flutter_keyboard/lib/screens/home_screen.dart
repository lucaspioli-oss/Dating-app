import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/keyboard_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isKeyboardEnabled = false;
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkKeyboardStatus();
    _urlController.text = 'http://localhost:3000';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkKeyboardStatus() async {
    final keyboardService = context.read<KeyboardService>();
    final isEnabled = await keyboardService.isKeyboardEnabled();
    setState(() {
      _isKeyboardEnabled = isEnabled;
    });
  }

  Future<void> _openKeyboardSettings() async {
    final keyboardService = context.read<KeyboardService>();
    await keyboardService.openKeyboardSettings();
  }

  Future<void> _saveSettings() async {
    final settings = context.read<AppSettings>();
    final keyboardService = context.read<KeyboardService>();

    settings.setBackendUrl(_urlController.text);
    await keyboardService.setBackendUrl(_urlController.text);
    await keyboardService.setDefaultTone(settings.selectedTone);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desenrola AI'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status do Teclado
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Configurações
            _buildSettingsCard(),
            const SizedBox(height: 24),

            // Instruções
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              _isKeyboardEnabled ? Icons.check_circle : Icons.error_outline,
              size: 64,
              color: _isKeyboardEnabled ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              _isKeyboardEnabled
                  ? 'Teclado Habilitado ✅'
                  : 'Teclado Não Habilitado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isKeyboardEnabled
                  ? 'Seu teclado customizado está pronto para uso!'
                  : 'Você precisa habilitar o teclado nas configurações',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!_isKeyboardEnabled) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openKeyboardSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Abrir Configurações'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // URL do Backend
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL do Backend',
                hintText: 'http://localhost:3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            // Seletor de Tom
            Consumer<AppSettings>(
              builder: (context, settings, _) {
                return DropdownButtonFormField<String>(
                  value: settings.selectedTone,
                  decoration: const InputDecoration(
                    labelText: 'Tom Padrão',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'engraçado',
                      child: Text('😄 Engraçado'),
                    ),
                    DropdownMenuItem(
                      value: 'ousado',
                      child: Text('🔥 Ousado'),
                    ),
                    DropdownMenuItem(
                      value: 'romântico',
                      child: Text('❤️ Romântico'),
                    ),
                    DropdownMenuItem(
                      value: 'casual',
                      child: Text('😎 Casual'),
                    ),
                    DropdownMenuItem(
                      value: 'confiante',
                      child: Text('💪 Confiante'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setSelectedTone(value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Botão Salvar
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Configurações'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como Usar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              '1',
              'Habilitar Teclado',
              'Vá em Ajustes > Geral > Teclado > Teclados > Adicionar Novo Teclado > Desenrola AI',
            ),
            _buildInstructionStep(
              '2',
              'Ativar Acesso Total',
              'Toque no Desenrola AI e ative "Permitir Acesso Total"',
            ),
            _buildInstructionStep(
              '3',
              'Copiar Mensagem',
              'Copie uma mensagem que você recebeu',
            ),
            _buildInstructionStep(
              '4',
              'Usar Teclado',
              'Troque para o Desenrola AI e toque em "Sugerir Resposta"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(number),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
