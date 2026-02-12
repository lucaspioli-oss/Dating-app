import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectInterestError),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileSavedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAccountTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showUserMenu(),
            tooltip: l10n.menuTooltip,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.person_outline),
              text: l10n.myProfileTab,
            ),
            Tab(
              icon: const Icon(Icons.credit_card),
              text: l10n.subscriptionTab,
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
    final l10n = AppLocalizations.of(context)!;
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
            _buildSectionTitle(l10n.basicInfoSection),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildAgeField(),
            const SizedBox(height: 16),
            _buildGenderField(),
            const SizedBox(height: 32),

            // Interesses
            _buildSectionTitle(l10n.interestsSection),
            const SizedBox(height: 8),
            Text(
              l10n.selectInterestsInfo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildInterestsChips(),
            const SizedBox(height: 32),

            // Não gosto
            _buildSectionTitle(l10n.dislikesSection),
            const SizedBox(height: 8),
            Text(
              l10n.avoidTopicsInfo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildDislikesChips(),
            const SizedBox(height: 32),

            // Estilo de Humor
            _buildSectionTitle(l10n.humorStyleSection),
            const SizedBox(height: 12),
            _buildHumorStyleCards(),
            const SizedBox(height: 32),

            // Objetivo
            _buildSectionTitle(l10n.relationshipGoalSection),
            const SizedBox(height: 12),
            _buildRelationshipGoalDropdown(),
            const SizedBox(height: 32),

            // Bio
            _buildSectionTitle(l10n.aboutYouSection),
            const SizedBox(height: 12),
            _buildBioField(),
            const SizedBox(height: 32),

            // Botão Salvar
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveProfileButton),
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
    final l10n = AppLocalizations.of(context)!;

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
              isActive ? l10n.activeSubscriptionStatus : l10n.inactiveSubscriptionStatus,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: subscriptionService.getExpirationMessage(),
              builder: (context, msgSnapshot) {
                return Text(
                  msgSnapshot.data ?? l10n.loadingTitle,
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.planDetailsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow(l10n.planLabel, _getPlanDisplayName(details.plan)),
            _buildDetailRow(l10n.statusLabel, details.status == 'active' ? l10n.activeSubscriptionStatus : details.status),
            if (details.expiresAt != null)
              _buildDetailRow(
                l10n.nextBillingLabel,
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.manageSubscriptionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (isActive) ...[
          OutlinedButton.icon(
            onPressed: () => _openSubscriptionManagement(),
            icon: const Icon(Icons.settings),
            label: Text(l10n.manageSubscriptionButton),
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
            label: Text(l10n.subscribeNowButton),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.subscriptionManagementInfo),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  String _getPlanDisplayName(String plan) {
    final l10n = AppLocalizations.of(context)!;
    switch (plan) {
      case 'daily':
        return l10n.planDaily;
      case 'weekly':
        return l10n.planWeekly;
      case 'monthly':
        return l10n.planMonthly;
      case 'quarterly':
        return l10n.planQuarterly;
      case 'yearly':
        return l10n.planYearly;
      default:
        return plan;
    }
  }

  void _showUserMenu() {
    final authService = FirebaseAuthService();
    final user = authService.currentUser;
    final l10n = AppLocalizations.of(context)!;

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
                          user?.email ?? l10n.notLoggedIn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          l10n.accountConnected,
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
              title: Text(l10n.settingsTitle),
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
              title: Text(l10n.logoutLabel, style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logoutTitle),
                    content: Text(l10n.logoutConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancelButton),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.logoutButton),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myProfileTab,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.basicInfoSection,
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
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.nameLabel,
        hintText: l10n.nameInputQuestion,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.nameInputRequired;
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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.genderLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people_outline),
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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.goalLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.favorite_outline),
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
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _bioController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: l10n.bioOptionalLabel,
        hintText: l10n.bioAboutYouHint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone widgets for bottom-tab navigation
// ---------------------------------------------------------------------------

class MyProfileContent extends StatefulWidget {
  const MyProfileContent({super.key});

  @override
  State<MyProfileContent> createState() => _MyProfileContentState();
}

class _MyProfileContentState extends State<MyProfileContent>
    with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  void _initProfile() {
    final profileProvider = context.read<UserProfileProvider>();

    if (profileProvider.isLoading) {
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectInterestError),
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
      preferredTone: 'casual',
      bio: _bioController.text.trim(),
    );

    final profileProvider = context.read<UserProfileProvider>();
    await profileProvider.saveProfile(profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileSavedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showUserMenu() {
    final authService = FirebaseAuthService();
    final user = authService.currentUser;
    final l10n = AppLocalizations.of(context)!;

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
                          user?.email ?? l10n.notLoggedIn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          l10n.accountConnected,
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
              title: Text(l10n.settingsTitle),
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
              title: Text(l10n.logoutLabel, style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logoutTitle),
                    content: Text(l10n.logoutConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancelButton),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.logoutButton),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfileTab),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showUserMenu(),
            tooltip: l10n.menuTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.basicInfoSection),
              const SizedBox(height: 16),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildAgeField(),
              const SizedBox(height: 16),
              _buildGenderField(),
              const SizedBox(height: 32),
              _buildSectionTitle(l10n.interestsSection),
              const SizedBox(height: 8),
              Text(
                l10n.selectInterestsInfo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _buildInterestsChips(),
              const SizedBox(height: 32),
              _buildSectionTitle(l10n.dislikesSection),
              const SizedBox(height: 8),
              Text(
                l10n.avoidTopicsInfo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _buildDislikesChips(),
              const SizedBox(height: 32),
              _buildSectionTitle(l10n.humorStyleSection),
              const SizedBox(height: 12),
              _buildHumorStyleCards(),
              const SizedBox(height: 32),
              _buildSectionTitle(l10n.relationshipGoalSection),
              const SizedBox(height: 12),
              _buildRelationshipGoalDropdown(),
              const SizedBox(height: 32),
              _buildSectionTitle(l10n.aboutYouSection),
              const SizedBox(height: 12),
              _buildBioField(),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveProfileButton),
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myProfileTab,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.basicInfoSection,
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
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.nameLabel,
        hintText: l10n.nameInputQuestion,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.nameInputRequired;
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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.genderLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people_outline),
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
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.goalLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.favorite_outline),
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
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _bioController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: l10n.bioOptionalLabel,
        hintText: l10n.bioAboutYouHint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription tab as a standalone widget
// ---------------------------------------------------------------------------

class SubscriptionContent extends StatelessWidget {
  const SubscriptionContent({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.subscriptionTab),
        centerTitle: true,
      ),
      body: SafeArea(
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
                _buildSubscriptionStatusCard(context, details, isActive),
                const SizedBox(height: 24),
                if (details != null && isActive) ...[
                  _buildPlanDetailsCard(context, details),
                  const SizedBox(height: 24),
                ],
                _buildSubscriptionActions(context, details, isActive, subscriptionService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(
    BuildContext context,
    SubscriptionDetails? details,
    bool isActive,
  ) {
    final subscriptionService = SubscriptionService();
    final l10n = AppLocalizations.of(context)!;

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
              isActive ? l10n.activeSubscriptionStatus : l10n.inactiveSubscriptionStatus,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: subscriptionService.getExpirationMessage(),
              builder: (context, msgSnapshot) {
                return Text(
                  msgSnapshot.data ?? l10n.loadingTitle,
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

  Widget _buildPlanDetailsCard(BuildContext context, SubscriptionDetails details) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.planDetailsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow(context, l10n.planLabel, _getPlanDisplayName(context, details.plan)),
            _buildDetailRow(context, l10n.statusLabel, details.status == 'active' ? l10n.activeSubscriptionStatus : details.status),
            if (details.expiresAt != null)
              _buildDetailRow(
                context,
                l10n.nextBillingLabel,
                '${details.expiresAt!.day}/${details.expiresAt!.month}/${details.expiresAt!.year}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
    BuildContext context,
    SubscriptionDetails? details,
    bool isActive,
    SubscriptionService subscriptionService,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.manageSubscriptionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (isActive) ...[
          OutlinedButton.icon(
            onPressed: () => _openSubscriptionManagement(context),
            icon: const Icon(Icons.settings),
            label: Text(l10n.manageSubscriptionButton),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ] else ...[
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
            label: Text(l10n.subscribeNowButton),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openSubscriptionManagement(BuildContext context) async {
    final url = Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.subscriptionManagementInfo),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  String _getPlanDisplayName(BuildContext context, String plan) {
    final l10n = AppLocalizations.of(context)!;
    switch (plan) {
      case 'daily':
        return l10n.planDaily;
      case 'weekly':
        return l10n.planWeekly;
      case 'monthly':
        return l10n.planMonthly;
      case 'quarterly':
        return l10n.planQuarterly;
      case 'yearly':
        return l10n.planYearly;
      default:
        return plan;
    }
  }
}
