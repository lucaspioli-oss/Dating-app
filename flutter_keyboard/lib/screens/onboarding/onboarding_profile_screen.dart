import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/user_profile_provider.dart';

class OnboardingProfileScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingProfileScreen({super.key, required this.onComplete});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '25');

  String _selectedLanguage = 'pt';
  String? _selectedHumorStyle;
  String? _selectedRelationshipGoal;

  final List<Map<String, String>> _languages = [
    {'value': 'pt', 'label': 'Portugues', 'flag': '🇧🇷', 'native': 'Portugues'},
    {'value': 'en', 'label': 'English', 'flag': '🇺🇸', 'native': 'English'},
    {'value': 'es', 'label': 'Espanol', 'flag': '🇪🇸', 'native': 'Espanol'},
  ];

  final Map<String, List<Map<String, String>>> _humorStylesByLang = {
    'pt': [
      {'value': 'sarcastico', 'label': 'Sarcastico'},
      {'value': 'engracado', 'label': 'Engracado'},
      {'value': 'casual', 'label': 'Casual'},
      {'value': 'intelectual', 'label': 'Intelectual'},
      {'value': 'fofo', 'label': 'Fofo'},
    ],
    'en': [
      {'value': 'sarcastico', 'label': 'Sarcastic'},
      {'value': 'engracado', 'label': 'Funny'},
      {'value': 'casual', 'label': 'Casual'},
      {'value': 'intelectual', 'label': 'Intellectual'},
      {'value': 'fofo', 'label': 'Sweet'},
    ],
    'es': [
      {'value': 'sarcastico', 'label': 'Sarcastico'},
      {'value': 'engracado', 'label': 'Gracioso'},
      {'value': 'casual', 'label': 'Casual'},
      {'value': 'intelectual', 'label': 'Intelectual'},
      {'value': 'fofo', 'label': 'Tierno'},
    ],
  };

  final Map<String, List<Map<String, String>>> _relationshipGoalsByLang = {
    'pt': [
      {'value': 'casual', 'label': 'Casual'},
      {'value': 'serio', 'label': 'Relacionamento serio'},
      {'value': 'amizade', 'label': 'Amizades'},
      {'value': 'conhecer pessoas', 'label': 'Conhecer pessoas'},
      {'value': 'ainda decidindo', 'label': 'Ainda decidindo'},
    ],
    'en': [
      {'value': 'casual', 'label': 'Casual'},
      {'value': 'serio', 'label': 'Serious relationship'},
      {'value': 'amizade', 'label': 'Friendships'},
      {'value': 'conhecer pessoas', 'label': 'Meet new people'},
      {'value': 'ainda decidindo', 'label': 'Still deciding'},
    ],
    'es': [
      {'value': 'casual', 'label': 'Casual'},
      {'value': 'serio', 'label': 'Relacion seria'},
      {'value': 'amizade', 'label': 'Amistades'},
      {'value': 'conhecer pessoas', 'label': 'Conocer personas'},
      {'value': 'ainda decidindo', 'label': 'Aun decidiendo'},
    ],
  };

  bool _isSaving = false;

  List<Map<String, String>> get _humorStyles =>
      _humorStylesByLang[_selectedLanguage] ?? _humorStylesByLang['pt']!;

  List<Map<String, String>> get _relationshipGoals =>
      _relationshipGoalsByLang[_selectedLanguage] ??
      _relationshipGoalsByLang['pt']!;

  // Localized strings for onboarding (before l10n is applied)
  Map<String, String> get _strings {
    switch (_selectedLanguage) {
      case 'en':
        return {
          'chooseLanguage': 'Choose your language',
          'whatIsYourName': 'What is your name?',
          'yourName': 'Your name',
          'yourAge': 'Your age',
          'minAge': 'You must be at least 18 years old',
          'humorStyle': 'What is your humor style?',
          'humorSubtitle': 'This helps the AI match your vibe',
          'whatAreYouLookingFor': 'What are you looking for?',
          'selectGoal': 'Select your main goal',
          'back': 'Back',
          'next': 'Next',
          'start': 'Start',
          'saveError': 'Error saving profile. Please try again.',
        };
      case 'es':
        return {
          'chooseLanguage': 'Elige tu idioma',
          'whatIsYourName': 'Como te llamas?',
          'yourName': 'Tu nombre',
          'yourAge': 'Tu edad',
          'minAge': 'Debes tener al menos 18 anos',
          'humorStyle': 'Cual es tu estilo de humor?',
          'humorSubtitle': 'Esto ayuda a la IA a combinar con tu estilo',
          'whatAreYouLookingFor': 'Que buscas?',
          'selectGoal': 'Selecciona tu objetivo principal',
          'back': 'Volver',
          'next': 'Siguiente',
          'start': 'Empezar',
          'saveError': 'Error al guardar perfil. Intenta de nuevo.',
        };
      default:
        return {
          'chooseLanguage': 'Escolha seu idioma',
          'whatIsYourName': 'Como voce se chama?',
          'yourName': 'Seu nome',
          'yourAge': 'Sua idade',
          'minAge': 'Voce precisa ter pelo menos 18 anos',
          'humorStyle': 'Qual seu estilo de humor?',
          'humorSubtitle': 'Isso ajuda a IA a combinar com seu jeito',
          'whatAreYouLookingFor': 'O que voce busca?',
          'selectGoal': 'Selecione seu objetivo principal',
          'back': 'Voltar',
          'next': 'Proximo',
          'start': 'Comecar',
          'saveError': 'Erro ao salvar perfil. Tente novamente.',
        };
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool _canAdvance() {
    switch (_currentPage) {
      case 0:
        return true; // Language always has a selection
      case 1:
        final age = int.tryParse(_ageController.text) ?? 0;
        return _nameController.text.trim().isNotEmpty && age >= 18;
      case 2:
        return _selectedHumorStyle != null;
      case 3:
        return _selectedRelationshipGoal != null;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (!_canAdvance()) return;

    if (_currentPage == 0) {
      // Apply language selection
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLocale(Locale(_selectedLanguage));
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndComplete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndComplete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final provider =
          Provider.of<UserProfileProvider>(context, listen: false);
      final existingProfile = provider.profile;

      final updatedProfile = existingProfile.copyWith(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 25,
        humorStyle: _selectedHumorStyle ?? 'casual',
        relationshipGoal: _selectedRelationshipGoal ?? 'conhecer pessoas',
      );

      await provider.saveProfile(updatedProfile);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboardingProfile', true);

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_strings['saveError']!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  // Dismiss keyboard when changing pages
                  FocusScope.of(context).unfocus();
                },
                children: [
                  _buildLanguagePage(),
                  _buildNameAgePage(),
                  _buildHumorStylePage(),
                  _buildRelationshipGoalPage(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildLanguagePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GradientText(
            text: 'Desenrola AI',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _strings['chooseLanguage']!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 48),
          ..._languages.map((lang) {
            final isSelected = _selectedLanguage == lang['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedLanguage = lang['value']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected ? null : AppColors.surfaceDark,
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppColors.elevatedDark, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        lang['native']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNameAgePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientText(
            text: _strings['whatIsYourName']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _nameController,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: _strings['yourName'],
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ageController,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: _strings['yourAge'],
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (_ageController.text.isNotEmpty &&
              (int.tryParse(_ageController.text) ?? 0) < 18 &&
              (int.tryParse(_ageController.text) ?? 0) > 0)
            Text(
              _strings['minAge']!,
              style:
                  const TextStyle(color: AppColors.error, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildHumorStylePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientText(
            text: _strings['humorStyle']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _strings['humorSubtitle']!,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _humorStyles.map((style) {
              final isSelected = _selectedHumorStyle == style['value'];
              return _buildSelectableChip(
                label: style['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedHumorStyle = style['value']);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientText(
            text: _strings['whatAreYouLookingFor']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _strings['selectGoal']!,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _relationshipGoals.map((goal) {
              final isSelected =
                  _selectedRelationshipGoal == goal['value'];
              return _buildSelectableChip(
                label: goal['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(
                      () => _selectedRelationshipGoal = goal['value']);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isSelected ? null : AppColors.surfaceDark,
          gradient: isSelected ? AppColors.primaryGradient : null,
          border: isSelected
              ? null
              : Border.all(color: AppColors.elevatedDark, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: isActive ? AppColors.buttonGradient : null,
                  color: isActive ? null : AppColors.elevatedDark,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: TextButton(
                    onPressed: _previousPage,
                    child: Text(
                      _strings['back']!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: GradientButton(
                  text: _currentPage == _totalPages - 1
                      ? _strings['start']!
                      : _strings['next']!,
                  onPressed: _canAdvance() ? _nextPage : null,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
