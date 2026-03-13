import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/user_profile.dart';

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

  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '25');

  String? _selectedHumorStyle;
  String? _selectedRelationshipGoal;

  final List<Map<String, String>> _humorStyles = [
    {'value': 'sarcástico', 'label': 'Sarcástico'},
    {'value': 'engraçado', 'label': 'Engraçado'},
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'intelectual', 'label': 'Intelectual'},
    {'value': 'fofo', 'label': 'Fofo'},
  ];

  final List<Map<String, String>> _relationshipGoals = [
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'sério', 'label': 'Relacionamento sério'},
    {'value': 'amizade', 'label': 'Amizades'},
    {'value': 'conhecer pessoas', 'label': 'Conhecer pessoas'},
    {'value': 'ainda decidindo', 'label': 'Ainda decidindo'},
  ];

  bool _isSaving = false;

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
        final age = int.tryParse(_ageController.text) ?? 0;
        return _nameController.text.trim().isNotEmpty && age >= 18;
      case 1:
        return _selectedHumorStyle != null;
      case 2:
        return _selectedRelationshipGoal != null;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (!_canAdvance()) return;

    if (_currentPage < 2) {
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
          const SnackBar(
            content: Text('Erro ao salvar perfil. Tente novamente.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
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
    );
  }

  Widget _buildNameAgePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GradientText(
            text: 'Como voce se chama?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Seu nome',
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: 'Sua idade',
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
            const Text(
              'Voce precisa ter pelo menos 18 anos',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildHumorStylePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GradientText(
            text: 'Qual seu estilo de humor?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Isso ajuda a IA a combinar com seu jeito',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GradientText(
            text: 'O que voce busca?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecione seu objetivo principal',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
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
            children: List.generate(3, (index) {
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
                    child: const Text(
                      'Voltar',
                      style: TextStyle(
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
                  text: _currentPage == 2 ? 'Começar' : 'Próximo',
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
