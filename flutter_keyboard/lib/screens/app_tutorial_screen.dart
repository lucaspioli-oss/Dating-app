import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

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

  final List<_TutorialPage> _pages = [
    _TutorialPage(
      icon: Icons.auto_awesome,
      title: 'Bem-vindo ao Desenrola AI!',
      subtitle: 'Seu assistente inteligente para conversas',
      description:
          'Vamos te mostrar como usar o app para nunca mais ficar sem '
          'assunto nas suas conversas.',
      steps: [],
    ),
    _TutorialPage(
      icon: Icons.person_add_alt_1,
      title: 'Crie um Perfil',
      subtitle: 'Para cada pessoa que você conversa',
      description:
          'Adicione informações sobre quem você esta conversando '
          'para receber sugestões mais personalizadas.',
      steps: [
        _TutorialStep(
          number: '1',
          text: 'Toque no botão + na tela de Contatos',
        ),
        _TutorialStep(
          number: '2',
          text: 'Escolha a plataforma (Tinder, Bumble, Instagram, WhatsApp...)',
        ),
        _TutorialStep(
          number: '3',
          text: 'Preencha o nome e as informações do perfil',
        ),
      ],
    ),
    _TutorialPage(
      icon: Icons.chat_bubble_outline,
      title: 'Adicione a Conversa',
      subtitle: 'Cole ou importe suas mensagens',
      description:
          'Para a IA entender o contexto, você precisa adicionar '
          'as mensagens da sua conversa.',
      steps: [
        _TutorialStep(
          number: '1',
          text: 'Abra o perfil do contato e vá em "Conversas"',
        ),
        _TutorialStep(
          number: '2',
          text: 'Tire um print da conversa ou importe do WhatsApp',
        ),
        _TutorialStep(
          number: '3',
          text: 'A IA analisa o histórico e entende o contexto',
        ),
      ],
    ),
    _TutorialPage(
      icon: Icons.keyboard_alt_outlined,
      title: 'Use o Teclado Inteligente',
      subtitle: 'O segredo esta aqui!',
      description:
          'O teclado Desenrola AI funciona dentro de qualquer app de mensagens. '
          'Ele e o jeito mais rapido de receber sugestões.',
      steps: [
        _TutorialStep(
          number: '1',
          text: 'Troque para o teclado Desenrola (globo 🌐)',
        ),
        _TutorialStep(
          number: '2',
          text: 'Selecione o contato certo no teclado',
        ),
        _TutorialStep(
          number: '3',
          text: 'Copie as mensagens novas que você recebeu',
        ),
        _TutorialStep(
          number: '4',
          text: 'Escolha uma sugestão e toque em "Inserir"',
        ),
      ],
      tip: 'Sempre envie suas respostas pelo teclado Desenrola! '
          'Assim a IA registra o que você enviou e melhora as '
          'sugestões futuras.',
    ),
    _TutorialPage(
      icon: Icons.format_list_numbered,
      title: 'Várias Mensagens?',
      subtitle: 'Cole uma por uma!',
      description:
          'Se a pessoa mandou várias mensagens seguidas, '
          'use o modo de multiplas mensagens do teclado.',
      steps: [
        _TutorialStep(
          number: '1',
          text: 'No teclado, toque em "Recebeu várias mensagens?"',
        ),
        _TutorialStep(
          number: '2',
          text: 'Copie a 1ª mensagem no app e toque em "Mensagem 1" para colar',
        ),
        _TutorialStep(
          number: '3',
          text: 'Repita para cada mensagem. Use o "+" se precisar de mais campos',
        ),
        _TutorialStep(
          number: '4',
          text: 'Toque em "Gerar Respostas" para receber sugestões',
        ),
      ],
      tip: 'A IA recebe todas as mensagens de uma vez e entende '
          'o contexto completo para gerar a melhor resposta!',
    ),
    _TutorialPage(
      icon: Icons.rocket_launch,
      title: 'Tudo Pronto!',
      subtitle: 'Comece a desenrolar',
      description:
          'Agora você já sabe o básico. Adicione seu primeiro contato '
          'e comece a receber sugestões personalizadas!',
      steps: [],
    ),
  ];

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
                  child: const Text('Pular'),
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
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
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

  Widget _buildPage(_TutorialPage page, int index) {
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
          if (index == 0) _buildWelcomeExtra(),
          if (index == _pages.length - 1) _buildReadyExtra(),

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

  Widget _buildWelcomeExtra() {
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
                _buildFeatureChip(Icons.smart_toy, 'IA Avançada'),
                const SizedBox(width: 8),
                _buildFeatureChip(Icons.speed, 'Respostas Rápidas'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFeatureChip(Icons.tune, 'Tons Personalizados'),
                const SizedBox(width: 8),
                _buildFeatureChip(Icons.apps, 'Multi-plataforma'),
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

  Widget _buildReadyExtra() {
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
                'Dica: você pode rever este tutorial a qualquer momento '
                'nas Configurações do app.',
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

  Widget _buildBottomButtons() {
    final isLastPage = _currentPage == _pages.length - 1;
    final isFirstPage = _currentPage == 0;

    if (isLastPage) {
      return GradientButton(
        text: 'Começar a usar!',
        icon: Icons.rocket_launch,
        onPressed: _completeTutorial,
      );
    }

    if (isFirstPage) {
      return GradientButton(
        text: 'Vamos lá!',
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
