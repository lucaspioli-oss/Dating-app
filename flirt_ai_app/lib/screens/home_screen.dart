import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/tone_selector.dart';
import '../widgets/suggestion_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flirt AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              _buildHeroSection(context),
              const SizedBox(height: 32),

              // Seletor de Tom
              const ToneSelector(),
              const SizedBox(height: 24),

              // Input de Mensagem
              _buildMessageInput(context),
              const SizedBox(height: 24),

              // Botão de Análise
              _buildAnalyzeButton(context),
              const SizedBox(height: 32),

              // Resultados
              _buildResults(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Transforme suas conversas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cole a mensagem que você recebeu e receba sugestões inteligentes de resposta',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensagem Recebida',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Cole aqui a mensagem que você recebeu...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              onPressed: () async {
                // TODO: Implementar paste do clipboard
              },
              tooltip: 'Colar do clipboard',
            ),
          ),
          onChanged: (value) {
            // Salvar no state se necessário
          },
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return FilledButton.icon(
          onPressed: appState.isLoading
              ? null
              : () {
                  // TODO: Implementar análise
                },
          icon: appState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            appState.isLoading ? 'Analisando...' : 'Analisar com IA',
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.messages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última Sugestão',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SuggestionCard(
              message: appState.messages.first,
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como Usar'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Escolha o tom da resposta'),
              SizedBox(height: 8),
              Text('2. Cole a mensagem recebida'),
              SizedBox(height: 8),
              Text('3. Toque em "Analisar com IA"'),
              SizedBox(height: 8),
              Text('4. Receba sugestões inteligentes!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
