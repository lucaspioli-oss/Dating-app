import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/agent_service.dart';

class AnalyzeProfileScreen extends StatefulWidget {
  const AnalyzeProfileScreen({super.key});

  @override
  State<AnalyzeProfileScreen> createState() => _AnalyzeProfileScreenState();
}

class _AnalyzeProfileScreenState extends State<AnalyzeProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoDescController = TextEditingController();

  String _selectedPlatform = 'tinder';
  bool _isLoading = false;
  String? _analysis;

  final List<Map<String, String>> _platforms = [
    {'value': 'tinder', 'label': '🔥 Tinder'},
    {'value': 'bumble', 'label': '💛 Bumble'},
    {'value': 'instagram', 'label': '📷 Instagram'},
    {'value': 'outro', 'label': '📱 Outro'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _photoDescController.dispose();
    super.dispose();
  }

  Future<void> _analyzeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _analysis = null;
    });

    try {
      final appState = context.read<AppState>();
      final profileProvider = context.read<UserProfileProvider>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeProfile(
        bio: _bioController.text.trim(),
        platform: _selectedPlatform,
        photoDescription: _photoDescController.text.trim().isEmpty
            ? null
            : _photoDescController.text.trim(),
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        userProfile: profileProvider.profile,
      );

      if (result.success && result.analysis != null) {
        setState(() {
          _analysis = result.analysis!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Análise concluída!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.errorMessage ?? 'Erro desconhecido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Copiado!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisar Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Plataforma
              _buildSectionTitle('Plataforma'),
              const SizedBox(height: 12),
              _buildPlatformSelector(),
              const SizedBox(height: 24),

              // Nome (opcional)
              _buildSectionTitle('Nome (Opcional)'),
              const SizedBox(height: 8),
              _buildNameField(),
              const SizedBox(height: 24),

              // Idade (opcional)
              _buildSectionTitle('Idade (Opcional)'),
              const SizedBox(height: 8),
              _buildAgeField(),
              const SizedBox(height: 24),

              // Bio
              _buildSectionTitle('Bio do Perfil *'),
              const SizedBox(height: 8),
              _buildBioField(),
              const SizedBox(height: 24),

              // Descrição das fotos (opcional)
              _buildSectionTitle('Descrição das Fotos/Posts (Opcional)'),
              const SizedBox(height: 8),
              _buildPhotoDescField(),
              const SizedBox(height: 32),

              // Botão Analisar
              _buildAnalyzeButton(),
              const SizedBox(height: 32),

              // Análise
              if (_analysis != null) _buildAnalysis(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Análise Inteligente',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Decodifique perfis e descubra a melhor estratégia!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
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

  Widget _buildPlatformSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _platforms.map((platform) {
        final isSelected = _selectedPlatform == platform['value'];
        return ChoiceChip(
          label: Text(platform['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedPlatform = platform['value']!;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nome',
        hintText: 'Ex: Maria, João...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Idade',
        hintText: 'Ex: 25',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.cake_outlined),
      ),
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 6,
      decoration: const InputDecoration(
        labelText: 'Bio',
        hintText: 'Cole aqui a bio completa do perfil...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Digite a bio do perfil para analisar';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoDescField() {
    return TextFormField(
      controller: _photoDescController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Descrição',
        hintText: 'Ex: 3 fotos na praia, 1 com cachorro, 2 viajando...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        helperText: 'Opcional: descreva fotos/posts para análise mais completa',
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _analyzeProfile,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.search),
      label: Text(_isLoading ? 'Analisando...' : 'Analisar Perfil'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Análise Completa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(_analysis!),
                  tooltip: 'Copiar análise',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _analysis!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
