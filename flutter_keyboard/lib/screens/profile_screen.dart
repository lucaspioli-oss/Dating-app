import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_profile_provider.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';
import '../services/subscription_service.dart';
import '../config/app_theme.dart';
import 'settings_screen.dart';
import 'auth/subscription_required_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  int _age = 18;
  String _gender = 'Prefiro não dizer';
  List<String> _selectedInterests = [];
  List<String> _selectedDislikes = [];
  String _humorStyle = 'casual';
  String _relationshipGoal = 'conhecer pessoas';

  final List<String> _genderOptions = [
    'Masculino',
    'Feminino',
    'Não-binário',
    'Prefiro não dizer',
  ];

  final List<String> _interestOptions = [
    'Música',
    'Filmes/Séries',
    'Esportes',
    'Viagens',
    'Gastronomia',
    'Arte',
    'Tecnologia',
    'Livros',
    'Jogos',
    'Fitness',
    'Natureza',
    'Fotografia',
    'Moda',
    'Pets',
    'Política',
    'Filosofia',
  ];

  final List<String> _dislikeOptions = [
    'Política',
    'Esportes',
    'Festas',
    'Bebidas alcoólicas',
    'Fumo',
    'Discussões sérias',
    'Piadas picantes',
    'Conversas superficiais',
  ];

  final List<Map<String, String>> _humorStyles = [
    {'value': 'sarcástico', 'label': '😏 Sarcástico'},
    {'value': 'engraçado', 'label': '😄 Engraçado'},
    {'value': 'casual', 'label': '😊 Casual'},
    {'value': 'intelectual', 'label': '🤓 Intelectual'},
    {'value': 'fofo', 'label': '🥰 Fofo'},
  ];

  final List<Map<String, String>> _relationshipGoals = [
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'sério', 'label': 'Relacionamento sério'},
    {'value': 'amizade', 'label': 'Amizades'},
    {'value': 'conhecer pessoas', 'label': 'Conhecer pessoas'},
    {'value': 'ainda decidindo', 'label': 'Ainda decidindo'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initProfile();
  }

  void _initProfile() {
    final profileProvider = context.read<UserProfileProvider>();

    if (profileProvider.isLoading) {
      // Provider still loading from SharedPreferences — listen for completion
      void listener() {
        if (!profileProvider.isLoading) {
          profileProvider.removeListener(listener);
          _populateFields(profileProvider.profile);
        }
      }
      profileProvider.addListener(listener);
    } else {
      _populateFields(profileProvider.profile);
    }
  }

  void _populateFields(UserProfile profile) {
    if (!mounted) return;
    setState(() {
      _nameController.text = profile.name;
      _bioController.text = profile.bio;
      _age = profile.age;
      _gender = profile.gender;
      _selectedInterests = List.from(profile.interests);
      _selectedDislikes = List.from(profile.dislikes);
      _humorStyle = profile.humorStyle;
      _relationshipGoal = profile.relationshipGoal;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um interesse!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: _age,
      gender: _gender,
      interests: _selectedInterests,
      dislikes: _selectedDislikes,
      humorStyle: _humorStyle,
      relationshipGoal: _relationshipGoal,
      preferredTone: 'casual', // Será sincronizado com o tom selecionado no chat
      bio: _bioController.text.trim(),
    );

    final profileProvider = context.read<UserProfileProvider>();
    await profileProvider.saveProfile(profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil salvo com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showUserMenu(),
            tooltip: 'Menu',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Meu Perfil',
            ),
            Tab(
              icon: Icon(Icons.credit_card),
              text: 'Assinatura',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildSubscriptionTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Informações Básicas
            _buildSectionTitle('Informações Básicas'),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildAgeField(),
            const SizedBox(height: 16),
            _buildGenderField(),
            const SizedBox(height: 32),

            // Interesses
            _buildSectionTitle('Meus Interesses'),
            const SizedBox(height: 8),
            Text(
              'Selecione o que você gosta',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildInterestsChips(),
            const SizedBox(height: 32),

            // Não gosto
            _buildSectionTitle('Não Gosto de'),
            const SizedBox(height: 8),
            Text(
              'Evitar esses tópicos nas conversas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildDislikesChips(),
            const SizedBox(height: 32),

            // Estilo de Humor
            _buildSectionTitle('Estilo de Humor'),
            const SizedBox(height: 12),
            _buildHumorStyleCards(),
            const SizedBox(height: 32),

            // Objetivo
            _buildSectionTitle('O que você busca?'),
            const SizedBox(height: 12),
            _buildRelationshipGoalDropdown(),
            const SizedBox(height: 32),

            // Bio
            _buildSectionTitle('Sobre Você'),
            const SizedBox(height: 12),
            _buildBioField(),
            const SizedBox(height: 32),

            // Botão Salvar
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Perfil'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    final subscriptionService = SubscriptionService();

    return SafeArea(
      child: FutureBuilder<SubscriptionDetails?>(
        future: subscriptionService.getSubscriptionDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = snapshot.data;
          final isActive = details?.isActive ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Card
              _buildSubscriptionStatusCard(details, isActive),
              const SizedBox(height: 24),

              // Plan Details
              if (details != null && isActive) ...[
                _buildPlanDetailsCard(details),
                const SizedBox(height: 24),
              ],

              // Actions
              _buildSubscriptionActions(details, isActive, subscriptionService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(SubscriptionDetails? details, bool isActive) {
    final subscriptionService = SubscriptionService();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isActive ? Icons.verified : Icons.info_outline,
              size: 64,
              color: isActive ? AppColors.success : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Assinatura Ativa' : 'Sem Assinatura',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: subscriptionService.getExpirationMessage(),
              builder: (context, msgSnapshot) {
                return Text(
                  msgSnapshot.data ?? 'Carregando...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailsCard(SubscriptionDetails details) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Plano',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('Plano', _getPlanDisplayName(details.plan)),
            _buildDetailRow('Status', details.status == 'active' ? 'Ativo' : details.status),
            if (details.expiresAt != null)
              _buildDetailRow(
                'Próxima cobrança',
                '${details.expiresAt!.day}/${details.expiresAt!.month}/${details.expiresAt!.year}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionActions(
    SubscriptionDetails? details,
    bool isActive,
    SubscriptionService subscriptionService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gerenciar Assinatura',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (isActive) ...[
          OutlinedButton.icon(
            onPressed: () => _openSubscriptionManagement(),
            icon: const Icon(Icons.settings),
            label: const Text('Gerenciar Assinatura'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ] else ...[
          // No subscription - navigate to Apple IAP subscription screen
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionRequiredScreen(
                    status: SubscriptionStatus.inactive,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star),
            label: const Text('Assinar Agora'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openSubscriptionManagement() async {
    // On iOS, open the App Store subscription management page
    final url = Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abra Ajustes > Apple ID > Assinaturas para gerenciar.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  String _getPlanDisplayName(String plan) {
    switch (plan) {
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      case 'quarterly':
        return 'Trimestral';
      case 'yearly':
        return 'Anual';
      default:
        return plan;
    }
  }

  void _showUserMenu() {
    final authService = FirebaseAuthService();
    final user = authService.currentUser;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (user?.email?.substring(0, 1) ?? 'U').toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Não logado',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Conta conectada',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Sair da conta', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sair da Conta'),
                    content: const Text('Tem certeza que deseja sair?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await authService.signOut();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu Perfil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'A IA usa essas informacoes para personalizar as respostas',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nome',
        hintText: 'Como você gostaria de ser chamado?',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, digite seu nome';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Idade: $_age anos'),
        Slider(
          value: _age.toDouble(),
          min: 18,
          max: 80,
          divisions: 62,
          label: '$_age anos',
          onChanged: (value) {
            setState(() {
              _age = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: const InputDecoration(
        labelText: 'Gênero',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.people_outline),
      ),
      items: _genderOptions.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _gender = value!;
        });
      },
    );
  }

  Widget _buildInterestsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(interest);
              } else {
                _selectedInterests.remove(interest);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDislikesChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dislikeOptions.map((dislike) {
        final isSelected = _selectedDislikes.contains(dislike);
        return FilterChip(
          label: Text(dislike),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDislikes.add(dislike);
              } else {
                _selectedDislikes.remove(dislike);
              }
            });
          },
          selectedColor: Theme.of(context).colorScheme.errorContainer,
        );
      }).toList(),
    );
  }

  Widget _buildHumorStyleCards() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _humorStyles.map((style) {
        final isSelected = _humorStyle == style['value'];
        return ChoiceChip(
          label: Text(style['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _humorStyle = style['value']!;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRelationshipGoalDropdown() {
    return DropdownButtonFormField<String>(
      value: _relationshipGoal,
      decoration: const InputDecoration(
        labelText: 'Objetivo',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.favorite_outline),
      ),
      items: _relationshipGoals.map((goal) {
        return DropdownMenuItem(
          value: goal['value'],
          child: Text(goal['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _relationshipGoal = value!;
        });
      },
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Bio (opcional)',
        hintText: 'Conte um pouco sobre você...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
