import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/agent_service.dart';
import '../services/conversation_service.dart';
import '../services/subscription_service.dart';
import 'conversation_detail_screen.dart';

class UnifiedAnalysisScreen extends StatefulWidget {
  const UnifiedAnalysisScreen({super.key});

  @override
  State<UnifiedAnalysisScreen> createState() => _UnifiedAnalysisScreenState();
}

class _UnifiedAnalysisScreenState extends State<UnifiedAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoDescController = TextEditingController();
  final _interestsController = TextEditingController();

  String _selectedPlatform = 'tinder';
  String _selectedAction = 'opener';
  bool _isLoading = false;
  bool _isAnalyzingImage = false;
  List<String> _suggestions = [];
  String? _analysis;
  final ImagePicker _picker = ImagePicker();

  // Para preview da imagem e dados de face
  Uint8List? _uploadedImageBytes;
  String? _uploadedImageBase64;
  String? _extractedUsername;
  String? _extractedFaceDescription;

  // Para responder mensagem
  final _lastMessageController = TextEditingController();

  // Developer mode - feedback com reasoning
  bool _isDeveloper = false;
  ReplyAnalysis? _replyAnalysis;
  List<SuggestionWithReasoning>? _suggestionsWithReasoning;
  final _feedbackNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkDeveloperStatus();
  }

  Future<void> _checkDeveloperStatus() async {
    final isDev = await SubscriptionService().isDeveloper();
    if (mounted) {
      setState(() {
        _isDeveloper = isDev;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _photoDescController.dispose();
    _interestsController.dispose();
    _lastMessageController.dispose();
    _feedbackNoteController.dispose();
    super.dispose();
  }

  Future<void> _uploadAndAnalyzeImage() async {
    try {
      // Comprimir imagem para evitar erros com fotos grandes do celular
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _uploadedImageBytes = bytes;
        _isAnalyzingImage = true;
      });

      final base64Image = base64Encode(bytes);

      // Sempre usar JPEG após compressão do image_picker
      String imageMediaType = 'image/jpeg';

      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeProfileImage(
        imageBase64: base64Image,
        platform: _selectedPlatform,
        imageMediaType: imageMediaType,
      );

      if (result.success) {
        setState(() {
          // Salvar imagem base64 para enviar ao criar conversa
          _uploadedImageBase64 = base64Image;

          if (result.name != null && result.name!.isNotEmpty) {
            _nameController.text = result.name!;
          }
          // Extrair idade
          if (result.age != null && result.age!.isNotEmpty) {
            _ageController.text = result.age!;
          }
          if (result.bio != null && result.bio!.isNotEmpty) {
            _bioController.text = result.bio!;
          }
          if (result.photoDescriptions != null && result.photoDescriptions!.isNotEmpty) {
            _photoDescController.text = result.photoDescriptions!.join('\n');
          }
          if (result.interests != null && result.interests!.isNotEmpty) {
            _interestsController.text = result.interests!.join(', ');
          }
          // Extrair username e descrição facial
          _extractedUsername = result.username;
          _extractedFaceDescription = result.faceDescription;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Perfil extraído com sucesso!'),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Erro ao analisar imagem'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
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
      _replyAnalysis = null;
      _suggestionsWithReasoning = null;
    });

    try {
      final appState = context.read<AppState>();
      final profileProvider = context.read<UserProfileProvider>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      if (_selectedAction == 'analyze') {
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
        } else {
          _showError(result.errorMessage ?? 'Erro desconhecido');
        }
      } else if (_selectedAction == 'reply') {
        // Gerar resposta para mensagem recebida
        if (_isDeveloper) {
          // Modo desenvolvedor: usa endpoint com reasoning
          final result = await agentService.generateReplyWithReasoning(
            receivedMessage: _lastMessageController.text.trim(),
            matchName: _nameController.text.trim(),
            platform: _selectedPlatform,
            context: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            userProfile: profileProvider.profile,
          );

          if (result.success && result.suggestions != null) {
            setState(() {
              _replyAnalysis = result.analysis;
              _suggestionsWithReasoning = result.suggestions;
              // Também preenche a lista simples para compatibilidade
              _suggestions = result.suggestions!.map((s) => s.text).toList();
            });
          } else {
            _showError(result.errorMessage ?? 'Erro desconhecido');
          }
        } else {
          // Modo normal: endpoint simples
          final result = await agentService.generateReply(
            receivedMessage: _lastMessageController.text.trim(),
            matchName: _nameController.text.trim(),
            platform: _selectedPlatform,
            context: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            userProfile: profileProvider.profile,
          );

          if (result.success && result.suggestions != null) {
            setState(() {
              _suggestions = result.suggestions!;
            });
          } else {
            _showError(result.errorMessage ?? 'Erro desconhecido');
          }
        }
      } else {
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copiado!'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _createConversationAndStart(String opener) async {
    try {
      final appState = context.read<AppState>();
      final conversationService = ConversationService(baseUrl: appState.backendUrl);

      final conversation = await conversationService.createConversation(
        matchName: _nameController.text.trim(),
        username: _extractedUsername,
        platform: _selectedPlatform,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        photoDescriptions: _photoDescController.text.trim().isEmpty
            ? null
            : _photoDescController.text.trim().split('\n'),
        age: _ageController.text.trim().isEmpty ? null : _ageController.text.trim(),
        interests: _interestsController.text.trim().isEmpty
            ? null
            : _interestsController.text.trim().split(',').map((e) => e.trim()).toList(),
        firstMessage: opener,
        tone: 'expert',
        faceImageBase64: _uploadedImageBase64,
        faceDescription: _extractedFaceDescription,
      );

      if (mounted) {
        // Mostrar mensagem apropriada se conversa já existia
        if (conversation.isExisting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conversa com ${_nameController.text.trim()} já existe. Mensagem adicionada!',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2196F3),
              duration: const Duration(seconds: 3),
            ),
          );
        }

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

  void _removeUploadedImage() {
    setState(() {
      _uploadedImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildUploadSection(),
              const SizedBox(height: 28),
              _buildSectionTitle('Plataforma'),
              const SizedBox(height: 12),
              _buildPlatformSelector(),
              const SizedBox(height: 28),
              _buildSectionTitle('O que você quer fazer?'),
              const SizedBox(height: 12),
              _buildActionSelector(),
              const SizedBox(height: 28),
              _buildInputFields(),
              if (_selectedAction == 'reply') ...[
                const SizedBox(height: 16),
                _buildLastMessageField(),
              ],
              const SizedBox(height: 16),
              _buildPhotoDescField(),
              const SizedBox(height: 28),
              _buildGenerateButton(),
              // Seção de análise para desenvolvedores (antes das sugestões)
              if (_isDeveloper && _replyAnalysis != null) ...[
                const SizedBox(height: 32),
                _buildDeveloperAnalysisSection(),
              ],
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 32),
                if (_isDeveloper && _suggestionsWithReasoning != null)
                  _buildSuggestionsWithReasoningSection()
                else
                  _buildSuggestionsSection(),
                // Seção de feedback para desenvolvedores - logo abaixo das sugestões
                if (_isDeveloper) ...[
                  const SizedBox(height: 20),
                  _buildDeveloperFeedbackSection(),
                ],
              ],
              if (_analysis != null) ...[
                const SizedBox(height: 32),
                _buildAnalysisSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Análise & Mensagens',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildUploadSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão de Upload
        Expanded(
          child: GestureDetector(
            onTap: _isAnalyzingImage ? null : _uploadAndAnalyzeImage,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isAnalyzingImage
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Analisando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload de Screenshot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Preenche os campos automaticamente',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        // Preview da imagem (se houver)
        if (_uploadedImageBytes != null) ...[
          const SizedBox(width: 12),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A3E), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _uploadedImageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _removeUploadedImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPlatformSelector() {
    final platforms = [
      {'value': 'tinder', 'label': 'Tinder', 'color': const Color(0xFFFF6B6B), 'icon': 'tinder'},
      {'value': 'bumble', 'label': 'Bumble', 'color': const Color(0xFFFFD93D), 'icon': 'bumble'},
      {'value': 'hinge', 'label': 'Hinge', 'color': const Color(0xFFE91E63), 'icon': 'hinge'},
      {'value': 'umatch', 'label': 'Umatch', 'color': const Color(0xFF8B5CF6), 'icon': 'umatch'},
      {'value': 'instagram', 'label': 'Instagram', 'color': const Color(0xFFE1306C), 'icon': 'instagram'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: platforms.map((platform) {
          final isSelected = _selectedPlatform == platform['value'];
          final color = platform['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlatform = platform['value'] as String;
                  if (_selectedPlatform == 'instagram' && _selectedAction == 'opener') {
                    _selectedAction = 'instagram_dm';
                  } else if (_selectedPlatform != 'instagram' && _selectedAction.startsWith('instagram_')) {
                    _selectedAction = 'opener';
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF2A2A3E),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlatformIcon(platform['icon'] as String, color, isSelected),
                    const SizedBox(width: 8),
                    Text(
                      platform['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlatformIcon(String platform, Color color, bool isSelected) {
    String? assetPath;

    switch (platform) {
      case 'tinder':
        assetPath = 'assets/images/tinder.png';
        break;
      case 'bumble':
        assetPath = 'assets/images/bumble.png';
        break;
      case 'hinge':
        assetPath = 'assets/images/hinge.png';
        break;
      case 'umatch':
        assetPath = 'assets/images/umatch.png';
        break;
      case 'instagram':
        assetPath = 'assets/images/instagram.png';
        break;
      default:
        assetPath = null;
    }

    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          assetPath,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.chat,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionSelector() {
    List<Map<String, String>> actions;

    if (_selectedPlatform == 'instagram') {
      actions = [
        {'value': 'instagram_dm', 'label': 'DM Direto'},
        {'value': 'instagram_story', 'label': 'Resposta Story'},
        {'value': 'instagram_post', 'label': 'Comentário'},
        {'value': 'analyze', 'label': 'Análise Completa'},
      ];
    } else {
      actions = [
        {'value': 'opener', 'label': 'Primeira Mensagem'},
        {'value': 'reply', 'label': 'Responder'},
        {'value': 'analyze', 'label': 'Análise Completa'},
      ];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          final isSelected = _selectedAction == action['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAction = action['value']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF2A2A3E),
                  ),
                ),
                child: Text(
                  action['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        // Primeira linha: Nome e Idade
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nome / Username',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _selectedPlatform == 'instagram' ? '@usuario' : 'Nome',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE91E63)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo obrigatório';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Idade',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '25',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE91E63)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segunda linha: Bio
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bio / Descrição',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Bio do perfil...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE91E63)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLastMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ultima mensagem dela',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OBRIGATORIO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _lastMessageController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Cole aqui a mensagem que ela mandou...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE91E63)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (_selectedAction == 'reply' && (value == null || value.trim().isEmpty)) {
              return 'Cole a mensagem dela para gerar resposta';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoDescField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descricao das Fotos (Opcional)',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _photoDescController,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'Ex: Na praia, com cachorro, viajando...',
            hintStyle: TextStyle(color: Colors.grey.shade700),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE91E63)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    String buttonText;
    if (_selectedAction == 'analyze') {
      buttonText = 'Analisar Perfil';
    } else if (_selectedAction == 'reply') {
      buttonText = 'Gerar Resposta';
    } else {
      buttonText = 'Gerar Mensagens';
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateContent,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE91E63).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões Geradas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Lista de sugestões em texto
        ...List.generate(_suggestions.length, (index) {
          return _buildSuggestionDetail(index, _suggestions[index]);
        }),
      ],
    );
  }

  Widget _buildSuggestionDetail(int index, String suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE91E63),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Opção ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copyToClipboard(suggestion),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _createConversationAndStart(suggestion),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Iniciar Conversa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE91E63),
                side: const BorderSide(color: Color(0xFFE91E63)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Análise do Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _copyToClipboard(_analysis!),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A3E)),
          ),
          child: Text(
            _analysis!,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DEVELOPER MODE WIDGETS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDeveloperAnalysisSection() {
    final analysis = _replyAnalysis!;

    String tempEmoji;
    Color tempColor;
    switch (analysis.messageTemperature) {
      case 'hot':
        tempEmoji = '🔥';
        tempColor = Colors.red;
        break;
      case 'cold':
        tempEmoji = '❄️';
        tempColor = Colors.blue;
        break;
      default:
        tempEmoji = '😐';
        tempColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEV MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Análise da IA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temperatura da mensagem
          Row(
            children: [
              Text(tempEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Temperatura: ${analysis.messageTemperature.toUpperCase()}',
                style: TextStyle(
                  color: tempColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fase da conversa
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'Fase: ${analysis.conversationPhase}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Intenção detectada
          if (analysis.detectedIntent.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Intenção: ${analysis.detectedIntent}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Elementos-chave
          if (analysis.keyElements.isNotEmpty) ...[
            const Text(
              'Elementos-chave:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analysis.keyElements.map((elem) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  elem,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsWithReasoningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões com Raciocínio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_suggestionsWithReasoning!.length, (index) {
          return _buildSuggestionWithReasoningCard(index, _suggestionsWithReasoning![index]);
        }),
      ],
    );
  }

  Widget _buildSuggestionWithReasoningCard(int index, SuggestionWithReasoning suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com número e botões
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE91E63),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (suggestion.strategy.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2196F3)),
                  ),
                  child: Text(
                    suggestion.strategy,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copyToClipboard(suggestion.text),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Texto da sugestão
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              suggestion.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          // Raciocínio
          if (suggestion.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.reasoning,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _createConversationAndStart(suggestion.text),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Iniciar Conversa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE91E63),
                side: const BorderSide(color: Color(0xFFE91E63)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.feedback_outlined, color: Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Feedback de Desenvolvimento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Como você avalia estas sugestões?',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Botões de feedback
          Row(
            children: [
              Expanded(
                child: _buildFeedbackButton(
                  'Bom',
                  Icons.thumb_up,
                  Colors.green,
                  () => _submitFeedback('good'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeedbackButton(
                  'Parcial',
                  Icons.thumbs_up_down,
                  Colors.orange,
                  () => _showFeedbackDialog('partial'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeedbackButton(
                  'Ruim',
                  Icons.thumb_down,
                  Colors.red,
                  () => _showFeedbackDialog('bad'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(String type) {
    _feedbackNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          type == 'bad' ? 'O que está errado?' : 'O que pode melhorar?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _feedbackNoteController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Descreva o problema ou sugestão de melhoria...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitFeedback(type, note: _feedbackNoteController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(String type, {String? note}) async {
    final appState = context.read<AppState>();
    final agentService = AgentService(baseUrl: appState.backendUrl);

    // Preparar dados de entrada
    final inputData = {
      'action': _selectedAction,
      'matchName': _nameController.text.trim(),
      'platform': _selectedPlatform,
      'bio': _bioController.text.trim(),
      'photoDescription': _photoDescController.text.trim(),
      if (_selectedAction == 'reply') 'receivedMessage': _lastMessageController.text.trim(),
    };

    // Preparar análise
    Map<String, dynamic>? analysisData;
    if (_replyAnalysis != null) {
      analysisData = {
        'messageTemperature': _replyAnalysis!.messageTemperature,
        'keyElements': _replyAnalysis!.keyElements,
        'detectedIntent': _replyAnalysis!.detectedIntent,
        'conversationPhase': _replyAnalysis!.conversationPhase,
      };
    }

    // Preparar sugestões
    List<Map<String, dynamic>> suggestionsData = [];
    if (_suggestionsWithReasoning != null) {
      suggestionsData = _suggestionsWithReasoning!.map((s) => {
        'text': s.text,
        'reasoning': s.reasoning,
        'strategy': s.strategy,
      }).toList();
    } else {
      suggestionsData = _suggestions.map((s) => {
        'text': s,
        'reasoning': '',
        'strategy': '',
      }).toList();
    }

    final success = await agentService.submitDeveloperFeedback(
      inputData: inputData,
      analysis: analysisData,
      suggestions: suggestionsData,
      feedbackType: type,
      feedbackNote: note,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Feedback enviado!' : 'Erro ao enviar feedback'),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
