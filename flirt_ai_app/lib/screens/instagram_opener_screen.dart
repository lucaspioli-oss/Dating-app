import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/agent_service.dart';

class InstagramOpenerScreen extends StatefulWidget {
  const InstagramOpenerScreen({super.key});

  @override
  State<InstagramOpenerScreen> createState() => _InstagramOpenerScreenState();
}

class _InstagramOpenerScreenState extends State<InstagramOpenerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _postsController = TextEditingController();
  final _storiesController = TextEditingController();
  final _specificPostController = TextEditingController();

  String _selectedApproach = 'dm_direto';
  bool _isLoading = false;
  List<String> _suggestions = [];

  final List<Map<String, dynamic>> _approaches = [
    {
      'value': 'dm_direto',
      'label': '💬 DM Direto',
      'icon': Icons.chat_bubble,
      'description': 'Mensagem direta sem contexto de post',
    },
    {
      'value': 'comentario_post',
      'label': '💬 Comentário em Post',
      'icon': Icons.comment,
      'description': 'Comentário público em foto/vídeo',
    },
    {
      'value': 'resposta_story',
      'label': '📸 Resposta a Story',
      'icon': Icons.photo_camera,
      'description': 'Responder a um story',
    },
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _postsController.dispose();
    _storiesController.dispose();
    _specificPostController.dispose();
    super.dispose();
  }

  Future<void> _generateOpener() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      final appState = context.read<AppState>();
      final profileProvider = context.read<UserProfileProvider>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      // Parse posts e stories
      List<String>? recentPosts;
      if (_postsController.text.trim().isNotEmpty) {
        recentPosts = _postsController.text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }

      List<String>? stories;
      if (_storiesController.text.trim().isNotEmpty) {
        stories = _storiesController.text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }

      final result = await agentService.generateInstagramOpener(
        username: _usernameController.text.trim(),
        approachType: _selectedApproach,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        recentPosts: recentPosts,
        stories: stories,
        specificPost: _specificPostController.text.trim().isEmpty
            ? null
            : _specificPostController.text.trim(),
        userProfile: profileProvider.profile,
      );

      if (result.success && result.suggestions != null) {
        setState(() {
          _suggestions = result.suggestions!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Opções geradas com sucesso!'),
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
        title: const Text('Instagram Opener'),
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

              // Tipo de Abordagem
              _buildSectionTitle('Tipo de Abordagem'),
              const SizedBox(height: 12),
              _buildApproachSelector(),
              const SizedBox(height: 24),

              // Username
              _buildSectionTitle('Username do Instagram'),
              const SizedBox(height: 8),
              _buildUsernameField(),
              const SizedBox(height: 24),

              // Bio (opcional)
              _buildSectionTitle('Bio (Opcional)'),
              const SizedBox(height: 8),
              _buildBioField(),
              const SizedBox(height: 24),

              // Posts recentes (opcional)
              _buildSectionTitle('Posts Recentes (Opcional)'),
              const SizedBox(height: 8),
              _buildPostsField(),
              const SizedBox(height: 24),

              // Stories (opcional)
              _buildSectionTitle('Stories Recentes (Opcional)'),
              const SizedBox(height: 8),
              _buildStoriesField(),
              const SizedBox(height: 24),

              // Post/Story específico
              if (_selectedApproach != 'dm_direto') ...[
                _buildSectionTitle(
                  _selectedApproach == 'comentario_post'
                      ? 'Post para Comentar *'
                      : 'Story para Responder *',
                ),
                const SizedBox(height: 8),
                _buildSpecificPostField(),
                const SizedBox(height: 24),
              ],

              // Botão Gerar
              _buildGenerateButton(),
              const SizedBox(height: 32),

              // Sugestões
              if (_suggestions.isNotEmpty) _buildSuggestions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.camera_alt,
              size: 48,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instagram Opener',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DMs, comentários e respostas a stories que geram conversa!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
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

  Widget _buildApproachSelector() {
    return Column(
      children: _approaches.map((approach) {
        final isSelected = _selectedApproach == approach['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedApproach = approach['value'];
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    approach['icon'] as IconData,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          approach['label'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          approach['description'],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username',
        hintText: 'Ex: maria_silva',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.alternate_email),
        prefixText: '@',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Digite o username do Instagram';
        }
        return null;
      },
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Bio',
        hintText: 'Cole aqui a bio do perfil...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildPostsField() {
    return TextFormField(
      controller: _postsController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Posts',
        hintText: 'Ex:\nFoto na praia com amigos\nVídeo fazendo trilha\nSelfie com cachorro',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        helperText: 'Uma descrição por linha',
      ),
    );
  }

  Widget _buildStoriesField() {
    return TextFormField(
      controller: _storiesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Stories',
        hintText: 'Ex:\nComendo pizza\nNo show de música\nViajando',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        helperText: 'Uma descrição por linha',
      ),
    );
  }

  Widget _buildSpecificPostField() {
    return TextFormField(
      controller: _specificPostController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: _selectedApproach == 'comentario_post' ? 'Descrição do Post' : 'Descrição do Story',
        hintText: _selectedApproach == 'comentario_post'
            ? 'Ex: Foto dele na praia ao pôr do sol'
            : 'Ex: Story mostrando comida japonesa',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Descreva o ${_selectedApproach == 'comentario_post' ? 'post' : 'story'} que você quer interagir';
        }
        return null;
      },
    );
  }

  Widget _buildGenerateButton() {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _generateOpener,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(_isLoading ? 'Gerando...' : 'Gerar Opções'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSuggestions() {
    String approachLabel = '';
    if (_selectedApproach == 'dm_direto') {
      approachLabel = 'DM';
    } else if (_selectedApproach == 'comentario_post') {
      approachLabel = 'Comentário';
    } else {
      approachLabel = 'Resposta ao Story';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('💬 Opções de $approachLabel'),
        const SizedBox(height: 16),
        ..._suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          child: Text('${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Opção ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(suggestion),
                          tooltip: 'Copiar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
