import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_profile_provider.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';
import '../services/subscription_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    _loadProfile();
  }

  void _loadProfile() {
    final profileProvider = context.read<UserProfileProvider>();
    final profile = profileProvider.profile;

    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _age = profile.age;
    _gender = profile.gender;
    _selectedInterests = List.from(profile.interests);
    _selectedDislikes = List.from(profile.dislikes);
    _humorStyle = profile.humorStyle;
    _relationshipGoal = profile.relationshipGoal;
  }

  @override
  void dispose() {
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
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Salvar perfil',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
            // Subscription info
            _buildSubscriptionCard(),
            const SizedBox(height: 16),

            // Account info & logout
            _buildAccountCard(),
            const SizedBox(height: 24),

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
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final subscriptionService = SubscriptionService();

    return FutureBuilder<SubscriptionDetails?>(
      future: subscriptionService.getSubscriptionDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final details = snapshot.data!;
        final isTrial = details.isTrial;
        final isPaid = details.isPaid;

        Color cardColor;
        IconData icon;
        String title;

        if (isPaid) {
          cardColor = Colors.green.shade50;
          icon = Icons.verified;
          title = 'Assinatura Ativa';
        } else if (isTrial) {
          cardColor = Colors.orange.shade50;
          icon = Icons.access_time;
          title = 'Período Trial';
        } else {
          cardColor = Colors.grey.shade100;
          icon = Icons.info_outline;
          title = 'Sem Assinatura';
        }

        return Card(
          elevation: 0,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: isPaid ? Colors.green : Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: subscriptionService.getExpirationMessage(),
                  builder: (context, msgSnapshot) {
                    return Text(
                      msgSnapshot.data ?? 'Carregando...',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                if (details.plan != 'trial') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Plano: ${details.plan == 'monthly' ? 'Mensal' : 'Anual'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountCard() {
    final authService = FirebaseAuthService();
    final user = authService.currentUser;

    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user?.email ?? 'Não logado',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
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
              icon: const Icon(Icons.logout),
              label: const Text('Sair da Conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.person,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure seu perfil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A IA usará essas informações para personalizar as respostas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
