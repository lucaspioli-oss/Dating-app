import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/agent_service.dart';
import '../services/conversation_service.dart';
import 'conversation_detail_screen.dart';

class UnifiedAnalysisScreen extends StatefulWidget {
  const UnifiedAnalysisScreen({super.key});

  @override
  State<UnifiedAnalysisScreen> createState() => _UnifiedAnalysisScreenState();
}

class _UnifiedAnalysisScreenState extends State<UnifiedAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoDescController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _interestsController = TextEditingController();

  String _selectedPlatform = 'tinder';
  String _selectedAction = 'opener'; // opener, instagram_dm, instagram_story, instagram_post, analyze
  bool _isLoading = false;
  bool _isAnalyzingImage = false;
  List<String> _suggestions = [];
  String? _analysis;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _platforms = [
    {'value': 'tinder', 'label': '🔥 Tinder'},
    {'value': 'bumble', 'label': '💛 Bumble'},
    {'value': 'hinge', 'label': '💕 Hinge'},
    {'value': 'instagram', 'label': '📸 Instagram'},
  ];

  final List<Map<String, String>> _actions = [
    {'value': 'opener', 'label': '💬 Primeira Mensagem', 'icon': 'chat'},
    {'value': 'instagram_dm', 'label': '📩 DM Instagram', 'icon': 'message'},
    {'value': 'instagram_story', 'label': '📱 Resposta Story', 'icon': 'story'},
    {'value': 'instagram_post', 'label': '❤️ Comentário Post', 'icon': 'favorite'},
    {'value': 'analyze', 'label': '🔍 Análise Completa', 'icon': 'analytics'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _photoDescController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _uploadAndAnalyzeImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isAnalyzingImage = true;
      });

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      String imageMediaType = 'image/jpeg';
      if (image.mimeType != null) {
        imageMediaType = image.mimeType!;
      } else if (image.path.toLowerCase().endsWith('.png')) {
        imageMediaType = 'image/png';
      } else if (image.path.toLowerCase().endsWith('.jpg') || image.path.toLowerCase().endsWith('.jpeg')) {
        imageMediaType = 'image/jpeg';
      }

      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeProfileImage(
        imageBase64: base64Image,
        platform: _selectedPlatform,
        imageMediaType: imageMediaType,
      );

      if (result.success) {
        setState(() {
          if (result.name != null && result.name!.isNotEmpty) {
            _nameController.text = result.name!;
          }
          if (result.bio != null && result.bio!.isNotEmpty) {
            _bioController.text = result.bio!;
          }
          if (result.photoDescriptions != null && result.photoDescriptions!.isNotEmpty) {
            _photoDescController.text = result.photoDescriptions!.join('\n');
          }
          if (result.location != null && result.location!.isNotEmpty) {
            _locationController.text = result.location!;
          }
          if (result.occupation != null && result.occupation!.isNotEmpty) {
            _occupationController.text = result.occupation!;
          }
          if (result.interests != null && result.interests!.isNotEmpty) {
            _interestsController.text = result.interests!.join(', ');
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Perfil extraído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.errorMessage ?? 'Erro ao analisar imagem'}'),
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
        _isAnalyzingImage = false;
      });
    }
  }

  Future<void> _generateContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _suggestions = [];
      _analysis = null;
    });

    try {
      final appState = context.read<AppState>();
      final profileProvider = context.read<UserProfileProvider>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      if (_selectedAction == 'analyze') {
        // Análise completa do perfil
        final result = await agentService.analyzeProfile(
          bio: _bioController.text.trim(),
          platform: _selectedPlatform,
          photoDescription: _photoDescController.text.trim().isEmpty ? null : _photoDescController.text.trim(),
          name: _nameController.text.trim(),
          userProfile: profileProvider.profile,
        );

        if (result.success && result.analysis != null) {
          setState(() {
            _analysis = result.analysis;
          });
        } else {
          _showError(result.errorMessage ?? 'Erro desconhecido');
        }
      } else if (_selectedAction.startsWith('instagram_')) {
        // Instagram openers
        String approachType = 'dm';
        if (_selectedAction == 'instagram_story') {
          approachType = 'story';
        } else if (_selectedAction == 'instagram_post') {
          approachType = 'comment';
        }

        final result = await agentService.generateInstagramOpener(
          username: _nameController.text.trim(),
          approachType: approachType,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          userProfile: profileProvider.profile,
        );

        if (result.success && result.suggestions != null) {
          setState(() {
            _suggestions = result.suggestions!;
          });
          _showSuccess('✨ Sugestões geradas!');
        } else {
          _showError(result.errorMessage ?? 'Erro desconhecido');
        }
      } else {
        // Primeira mensagem (opener para dating apps)
        final result = await agentService.generateFirstMessage(
          matchName: _nameController.text.trim(),
          matchBio: _bioController.text.trim(),
          platform: _selectedPlatform,
          photoDescription: _photoDescController.text.trim().isEmpty ? null : _photoDescController.text.trim(),
          userProfile: profileProvider.profile,
        );

        if (result.success && result.suggestions != null) {
          setState(() {
            _suggestions = result.suggestions!;
          });
          _showSuccess('✨ Mensagens geradas!');
        } else {
          _showError(result.errorMessage ?? 'Erro desconhecido');
        }
      }
    } catch (e) {
      _showError('Erro: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red),
      );
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

  Future<void> _createConversationAndStart(String opener) async {
    try {
      final appState = context.read<AppState>();
      final conversationService = ConversationService(baseUrl: appState.backendUrl);

      // Criar nova conversa com o opener
      final conversation = await conversationService.createConversation(
        matchName: _nameController.text.trim(),
        platform: _selectedPlatform,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        photoDescriptions: _photoDescController.text.trim().isEmpty
            ? null
            : _photoDescController.text.trim().split('\n'),
        age: null,
        interests: _interestsController.text.trim().isEmpty
            ? null
            : _interestsController.text.trim().split(',').map((e) => e.trim()).toList(),
        firstMessage: opener,
        tone: 'expert', // Expert mode - calibra automaticamente
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Conversa criada! Abrindo...'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar para a tela de conversa
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(conversationId: conversation.id),
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao criar conversa: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise & Mensagens'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildUploadButton(),
              const SizedBox(height: 24),
              _buildSectionTitle('Plataforma'),
              const SizedBox(height: 12),
              _buildPlatformSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('O que você quer fazer?'),
              const SizedBox(height: 12),
              _buildActionSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Nome / Username'),
              const SizedBox(height: 8),
              _buildNameField(),
              const SizedBox(height: 24),
              _buildSectionTitle('Bio / Descrição'),
              const SizedBox(height: 8),
              _buildBioField(),
              const SizedBox(height: 24),
              _buildSectionTitle('Descrição das Fotos (Opcional)'),
              const SizedBox(height: 8),
              _buildPhotoDescField(),
              const SizedBox(height: 32),
              _buildGenerateButton(),
              const SizedBox(height: 32),
              if (_analysis != null) _buildAnalysis(),
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
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tudo em Um Lugar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload de screenshot + Geração de mensagens',
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

  Widget _buildUploadButton() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: _isAnalyzingImage ? null : _uploadAndAnalyzeImage,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (_isAnalyzingImage)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.upload_file, size: 32, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnalyzingImage ? 'Analisando screenshot...' : '📸 Upload de Screenshot',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAnalyzingImage
                          ? 'Extraindo informações do perfil...'
                          : 'Tire print do perfil e preencha automaticamente',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
              if (!_isAnalyzingImage)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              // Ajustar ação padrão baseado na plataforma
              if (_selectedPlatform == 'instagram' && _selectedAction == 'opener') {
                _selectedAction = 'instagram_dm';
              } else if (_selectedPlatform != 'instagram' && _selectedAction.startsWith('instagram_')) {
                _selectedAction = 'opener';
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildActionSelector() {
    List<Map<String, String>> availableActions = _actions;

    // Filtrar ações baseado na plataforma
    if (_selectedPlatform == 'instagram') {
      availableActions = _actions.where((action) =>
        action['value'] == 'instagram_dm' ||
        action['value'] == 'instagram_story' ||
        action['value'] == 'instagram_post' ||
        action['value'] == 'analyze'
      ).toList();
    } else {
      availableActions = _actions.where((action) =>
        action['value'] == 'opener' ||
        action['value'] == 'analyze'
      ).toList();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableActions.map((action) {
        final isSelected = _selectedAction == action['value'];
        return ChoiceChip(
          label: Text(action['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedAction = action['value']!;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: _selectedPlatform == 'instagram' ? 'Username' : 'Nome',
        hintText: _selectedPlatform == 'instagram' ? 'Ex: @fulana' : 'Ex: Maria, João...',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return _selectedPlatform == 'instagram' ? 'Digite o username' : 'Digite o nome';
        }
        return null;
      },
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Bio',
        hintText: 'Cole aqui a bio do perfil...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Digite a bio do perfil';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoDescField() {
    return TextFormField(
      controller: _photoDescController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Descrição',
        hintText: 'Ex: Na praia, com cachorro, viajando...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        helperText: 'Opcional: descreva as fotos para personalizar mais',
      ),
    );
  }

  Widget _buildGenerateButton() {
    String buttonText = 'Gerar';
    if (_selectedAction == 'analyze') {
      buttonText = 'Analisar Perfil';
    } else if (_selectedAction.startsWith('instagram_')) {
      buttonText = 'Gerar Sugestões';
    } else {
      buttonText = 'Gerar Mensagens';
    }

    return FilledButton.icon(
      onPressed: _isLoading ? null : _generateContent,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(_isLoading ? 'Gerando...' : buttonText),
      style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
    );
  }

  Widget _buildAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🔍 Análise do Perfil'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Análise Completa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(_analysis!),
                      tooltip: 'Copiar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _analysis!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('💬 Sugestões Geradas'),
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
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _createConversationAndStart(suggestion),
                      icon: const Icon(Icons.chat),
                      label: const Text('Iniciar Conversa com Esta'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
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
