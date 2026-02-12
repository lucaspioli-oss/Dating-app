import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/keyboard_service.dart';
import '../config/app_theme.dart';

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

  final List<_SetupStep> _steps = [
    _SetupStep(
      icon: Icons.keyboard_alt_outlined,
      title: 'Ative o Teclado Desenrola AI',
      description:
          'Para usar sugestões inteligentes direto no WhatsApp, Tinder e outros apps, '
          'você precisa ativar nosso teclado personalizado.',
      instruction: 'Vá em:\nAjustes → Geral → Teclado → Teclados → Adicionar',
    ),
    _SetupStep(
      icon: Icons.security_outlined,
      title: 'Ative o Acesso Completo',
      description:
          'Ao ativar, a Apple exibe um aviso de segurança padrão que pode parecer '
          'assustador — mas fique tranquilo! Esse aviso aparece para TODOS os '
          'teclados com IA. No nosso caso, o acesso '
          'completo é necessário apenas para conectar o teclado à inteligência '
          'artificial e gerar sugestões personalizadas.',
      instruction:
          'Selecione "Desenrola AI" e ative "Permitir Acesso Completo"',
      tip: 'Para proteger dados sensíveis como senhas e cartões de crédito, '
          'basta trocar para o teclado padrão do iPhone (toque no globo 🌐) '
          'antes de digitar essas informações.',
    ),
    _SetupStep(
      icon: Icons.swap_horiz,
      title: 'Troque para o Teclado',
      description:
          'Em qualquer app de mensagens, toque no ícone do globo (🌐) '
          'no canto inferior esquerdo do teclado para trocar para o Desenrola AI.',
      instruction: 'Toque no globo 🌐 para alternar entre teclados',
    ),
  ];

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeSetup,
                child: const Text('Pular'),
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
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildStepPage(_steps[index], index);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
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
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPage(_SetupStep step, int index) {
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
                        ? 'Teclado ativado!'
                        : 'Teclado não ativado',
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

  Widget _buildBottomButtons() {
    if (_currentPage == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientButton(
            text: 'Abrir Configurações',
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
            child: const Text('Próximo'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _completeSetup,
            child: Text(
              'Continuar sem o teclado',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ],
      );
    }

    if (_currentPage == _steps.length - 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientButton(
            text: 'Começar a usar!',
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
            child: const Text('Voltar'),
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
            child: const Text('Próximo'),
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
