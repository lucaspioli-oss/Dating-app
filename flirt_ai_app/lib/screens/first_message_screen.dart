import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/agent_service.dart';

class FirstMessageScreen extends StatefulWidget {
  const FirstMessageScreen({super.key});

  @override
  State<FirstMessageScreen> createState() => _FirstMessageScreenState();
}

class _FirstMessageScreenState extends State<FirstMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoDescController = TextEditingController();

  String _selectedPlatform = 'tinder';
  bool _isLoading = false;
  bool _isAnalyzingImage = false;
  List<String> _suggestions = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _platforms = [
    {'value': 'tinder', 'label': '🔥 Tinder'},
    {'value': 'bumble', 'label': '💛 Bumble'},
    {'value': 'hinge', 'label': '💕 Hinge'},
    {'value': 'outro', 'label': '📱 Outro'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _photoDescController.dispose();
    super.dispose();
  }

  Future<void> _generateFirstMessage() async {
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

      final result = await agentService.generateFirstMessage(
        matchName: _nameController.text.trim(),
        matchBio: _bioController.text.trim(),
        platform: _selectedPlatform,
        photoDescription: _photoDescController.text.trim().isEmpty
            ? null
            : _photoDescController.text.trim(),
        userProfile: profileProvider.profile,
      );

      if (result.success && result.suggestions != null) {
        setState(() {
          _suggestions = result.suggestions!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Mensagens geradas com sucesso!'),
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

  Future<void> _uploadAndAnalyzeImage() async {
    try {
      // Selecionar imagem
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() {
        _isAnalyzingImage = true;
      });

      // Ler bytes da imagem
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Detectar tipo de imagem do arquivo
      String imageMediaType = 'image/jpeg';
      if (image.mimeType != null) {
        imageMediaType = image.mimeType!;
      } else if (image.path.toLowerCase().endsWith('.png')) {
        imageMediaType = 'image/png';
      } else if (image.path.toLowerCase().endsWith('.jpg') || image.path.toLowerCase().endsWith('.jpeg')) {
        imageMediaType = 'image/jpeg';
      } else if (image.path.toLowerCase().endsWith('.gif')) {
        imageMediaType = 'image/gif';
      } else if (image.path.toLowerCase().endsWith('.webp')) {
        imageMediaType = 'image/webp';
      }

      // Chamar API para análise
      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeProfileImage(
        imageBase64: base64Image,
        platform: _selectedPlatform,
        imageMediaType: imageMediaType,
      );

      if (result.success) {
        // Preencher campos automaticamente
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
                      _isAnalyzingImage
                          ? 'Analisando screenshot...'
                          : '📸 Upload de Screenshot',
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primeira Mensagem'),
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

              // Botão Upload Screenshot
              _buildUploadButton(),
              const SizedBox(height: 24),

              // Plataforma
              _buildSectionTitle('Plataforma'),
              const SizedBox(height: 12),
              _buildPlatformSelector(),
              const SizedBox(height: 24),

              // Nome do match
              _buildSectionTitle('Nome do Match'),
              const SizedBox(height: 8),
              _buildNameField(),
              const SizedBox(height: 24),

              // Bio
              _buildSectionTitle('Bio do Perfil'),
              const SizedBox(height: 8),
              _buildBioField(),
              const SizedBox(height: 24),

              // Descrição da foto (opcional)
              _buildSectionTitle('Descrição das Fotos (Opcional)'),
              const SizedBox(height: 8),
              _buildPhotoDescField(),
              const SizedBox(height: 32),

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
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.message_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primeiras Mensagens Criativas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evite clichês e comece conversas memoráveis!',
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Digite o nome do match';
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
    return FilledButton.icon(
      onPressed: _isLoading ? null : _generateFirstMessage,
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
      label: Text(_isLoading ? 'Gerando...' : 'Gerar Mensagens'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
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
