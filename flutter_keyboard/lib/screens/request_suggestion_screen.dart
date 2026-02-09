import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/profile_model.dart';
import '../providers/app_state.dart';
import '../services/agent_service.dart';
import '../services/conversation_service.dart';
import '../services/profile_service.dart';
import '../widgets/profile_avatar.dart';
import 'conversation_detail_screen.dart';

/// Tipos de ação disponíveis
enum ActionType {
  // Instagram
  primeiraDm,
  responderStory,
  continuarConversaInstagram,

  // Bumble
  responderOpeningMove,
  primeiraEnviada,
  continuarConversaBumble,

  // Tinder/Hinge/Outros
  primeiraMensagem,
  continuarConversa,
}

extension ActionTypeExtension on ActionType {
  String get displayName {
    switch (this) {
      case ActionType.primeiraDm:
        return 'Primeira DM';
      case ActionType.responderStory:
        return 'Responder Story';
      case ActionType.continuarConversaInstagram:
        return 'Continuar Conversa';
      case ActionType.responderOpeningMove:
        return 'Responder Opening Move';
      case ActionType.primeiraEnviada:
        return 'Primeira Mensagem';
      case ActionType.continuarConversaBumble:
        return 'Continuar Conversa';
      case ActionType.primeiraMensagem:
        return 'Primeira Mensagem';
      case ActionType.continuarConversa:
        return 'Continuar Conversa';
    }
  }

  String get description {
    switch (this) {
      case ActionType.primeiraDm:
        return 'Enviar mensagem direta pela primeira vez';
      case ActionType.responderStory:
        return 'Responder ao story dela';
      case ActionType.continuarConversaInstagram:
        return 'Dar continuidade na conversa';
      case ActionType.responderOpeningMove:
        return 'Responder a pergunta dela';
      case ActionType.primeiraEnviada:
        return 'Ela fez match e você envia primeiro';
      case ActionType.continuarConversaBumble:
        return 'Dar continuidade na conversa';
      case ActionType.primeiraMensagem:
        return 'Enviar a primeira mensagem';
      case ActionType.continuarConversa:
        return 'Dar continuidade na conversa';
    }
  }

  IconData get icon {
    switch (this) {
      case ActionType.primeiraDm:
        return Icons.send;
      case ActionType.responderStory:
        return Icons.auto_stories;
      case ActionType.continuarConversaInstagram:
      case ActionType.continuarConversaBumble:
      case ActionType.continuarConversa:
        return Icons.chat;
      case ActionType.responderOpeningMove:
        return Icons.question_answer;
      case ActionType.primeiraEnviada:
      case ActionType.primeiraMensagem:
        return Icons.waving_hand;
    }
  }

  bool get needsLastMessage {
    return this == ActionType.continuarConversa ||
        this == ActionType.continuarConversaBumble ||
        this == ActionType.continuarConversaInstagram;
  }
}

class RequestSuggestionScreen extends StatefulWidget {
  final Profile profile;

  const RequestSuggestionScreen({
    super.key,
    required this.profile,
  });

  @override
  State<RequestSuggestionScreen> createState() => _RequestSuggestionScreenState();
}

class _RequestSuggestionScreenState extends State<RequestSuggestionScreen> {
  final ImagePicker _picker = ImagePicker();
  final ConversationService _conversationService = ConversationService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _messageController = TextEditingController();

  // Estado do fluxo
  int _step = 0; // 0 = plataforma, 1 = ação, 2 = story/mensagem, 3 = gerando
  PlatformType? _selectedPlatform;
  ActionType? _selectedAction;
  StoryData? _selectedStory;
  String? _lastMessage;
  Uint8List? _lastMessageImageBytes;
  bool _useTextInput = false; // true = digitar, false = print

  bool _isGenerating = false;
  List<String> _suggestions = [];
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => _goBack(),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  String _getTitle() {
    switch (_step) {
      case 0:
        return 'Selecione a Plataforma';
      case 1:
        return 'O que você quer fazer?';
      case 2:
        if (_selectedAction == ActionType.responderStory) {
          return 'Selecione o Story';
        }
        return 'Última Mensagem Dela';
      case 3:
        return 'Sugestões';
      default:
        return 'Nova Sugestão';
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() {
        _step--;
        if (_step == 0) {
          _selectedPlatform = null;
          _selectedAction = null;
        } else if (_step == 1) {
          _selectedAction = null;
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return _buildGeneratingState();
    }

    if (_suggestions.isNotEmpty) {
      return _buildSuggestionsState();
    }

    switch (_step) {
      case 0:
        return _buildPlatformStep();
      case 1:
        return _buildActionStep();
      case 2:
        return _buildContextStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlatformStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info do perfil
          _buildProfileInfo(),
          const SizedBox(height: 24),

          // Instagram (se tiver)
          if (widget.profile.hasInstagram) ...[
            const Text(
              'REDES SOCIAIS',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlatformButton(PlatformType.instagram),
            const SizedBox(height: 24),
          ],

          // Apps de relacionamento
          if (widget.profile.hasDatingApps) ...[
            const Text(
              'APPS DE RELACIONAMENTO',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.profile.datingApps.map((app) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlatformButton(app.type),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ProfileAvatar.fromBase64(
            base64Image: widget.profile.faceImageBase64,
            name: widget.profile.name,
            size: 52,
            showShadow: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: widget.profile.platforms.values.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(p.type.icon, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformButton(PlatformType platform) {
    final platformData = widget.profile.platforms[platform];
    final hasStories = platform == PlatformType.instagram &&
        widget.profile.stories.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlatform = platform;
          _step = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          children: [
            Text(platform.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (platformData?.username != null)
                    Text(
                      '@${platformData!.username}',
                      style: const TextStyle(
                        color: Color(0xFFE91E63),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (hasStories)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF58529), Color(0xFFDD2A7B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.profile.stories.length} stories',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStep() {
    final actions = _getActionsForPlatform(_selectedPlatform!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plataforma selecionada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _selectedPlatform!.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedPlatform!.displayName,
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ações disponíveis
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActionButton(action),
            );
          }),
        ],
      ),
    );
  }

  List<ActionType> _getActionsForPlatform(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return [
          ActionType.primeiraDm,
          if (widget.profile.stories.isNotEmpty) ActionType.responderStory,
          ActionType.continuarConversaInstagram,
        ];
      case PlatformType.bumble:
        final hasOpeningMove =
            widget.profile.platforms[PlatformType.bumble]?.openingMove != null;
        return [
          if (hasOpeningMove) ActionType.responderOpeningMove,
          ActionType.primeiraEnviada,
          ActionType.continuarConversaBumble,
        ];
      default:
        return [
          ActionType.primeiraMensagem,
          ActionType.continuarConversa,
        ];
    }
  }

  Widget _buildActionButton(ActionType action) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAction = action;
          if (action == ActionType.responderStory ||
              action.needsLastMessage ||
              action == ActionType.responderOpeningMove) {
            _step = 2;
          } else {
            // Gerar direto
            _generateSuggestions();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action.icon,
                color: const Color(0xFFE91E63),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    action.description,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextStep() {
    if (_selectedAction == ActionType.responderStory) {
      return _buildStorySelector();
    } else if (_selectedAction == ActionType.responderOpeningMove) {
      return _buildOpeningMoveContext();
    } else {
      return _buildLastMessageInput();
    }
  }

  Widget _buildStorySelector() {
    final stories = widget.profile.stories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione o story para responder:',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...stories.map((story) {
            Uint8List? imageBytes;
            if (story.imageBase64 != null) {
              try {
                imageBytes = base64Decode(story.imageBase64!);
              } catch (_) {}
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStory = story;
                });
                _generateSuggestions();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF2A2A3E),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageBytes != null
                            ? Image.memory(imageBytes, fit: BoxFit.cover)
                            : const Icon(Icons.image, color: Color(0xFF666666)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.description ?? 'Story sem descrição',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(story.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF666666),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOpeningMoveContext() {
    final openingMove =
        widget.profile.platforms[PlatformType.bumble]?.openingMove;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opening Move dela:',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A3E)),
            ),
            child: Text(
              openingMove ?? 'Pergunta não extraída',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _generateSuggestions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Gerar Sugestões',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastMessageInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como você quer informar a mensagem dela?',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Toggle entre as opções
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _useTextInput = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_useTextInput
                            ? const Color(0xFFE91E63)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            color: !_useTextInput
                                ? Colors.white
                                : const Color(0xFF888888),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Print',
                            style: TextStyle(
                              color: !_useTextInput
                                  ? Colors.white
                                  : const Color(0xFF888888),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _useTextInput = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _useTextInput
                            ? const Color(0xFFE91E63)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard,
                            color: _useTextInput
                                ? Colors.white
                                : const Color(0xFF888888),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Digitar',
                            style: TextStyle(
                              color: _useTextInput
                                  ? Colors.white
                                  : const Color(0xFF888888),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conteúdo baseado na opção selecionada
          if (_useTextInput) ...[
            const Text(
              'Digite a última mensagem que ela enviou:',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cole ou digite a mensagem aqui...',
                hintStyle: const TextStyle(color: Color(0xFF666666)),
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
              ),
              onChanged: (value) {
                setState(() {
                  _lastMessage = value;
                });
              },
            ),
            const SizedBox(height: 24),
            if (_messageController.text.trim().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _lastMessage = _messageController.text.trim();
                    _generateSuggestionsFromText();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Gerar Sugestões',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ] else ...[
            // Opção: Upload de print
            GestureDetector(
              onTap: () => _pickLastMessageImage(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: _lastMessageImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _lastMessageImageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: Color(0xFF888888), size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Toque para fazer upload do print',
                            style: TextStyle(color: Color(0xFF888888)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A IA vai analisar a conversa automaticamente',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            if (_lastMessageImageBytes != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _generateSuggestions(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Gerar Sugestões',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFE91E63)),
          SizedBox(height: 24),
          Text(
            'Gerando sugestões...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Analisando o perfil e contexto',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha uma sugestão:',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ..._suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildSuggestionCard(index, suggestion),
            );
          }),
          // Opção 4: Mensagem personalizada
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildCustomMessageCard(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _generateSuggestions(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE91E63)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Gerar Novas Sugestões',
                style: TextStyle(
                  color: Color(0xFFE91E63),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMessageCard() {
    return GestureDetector(
      onTap: () => _showCustomMessageDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Escrever minha própria mensagem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomMessageDialog() {
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Sua mensagem',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: customController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Digite sua mensagem personalizada...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF0D0D1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () {
              if (customController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _useSuggestion(customController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Usar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(int index, String suggestion) {
    return Container(
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Botão Copiar
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: suggestion));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copiado!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy, color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Copiar',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão Usar
              Expanded(
                child: GestureDetector(
                  onTap: () => _useSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Usar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min atrás';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h atrás';
    } else {
      return '${diff.inDays}d atrás';
    }
  }

  Future<void> _pickLastMessageImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _lastMessageImageBytes = bytes;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar imagem: $e';
      });
    }
  }

  Future<void> _generateSuggestions() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(this.context, listen: false);
      final agentService = AgentService(baseUrl: appState.backendUrl);

      // Construir o contexto para a IA
      String aiContext = _buildContextForAI();

      // Usar o generateFirstMessage com contexto adicional
      final result = await agentService.generateFirstMessage(
        matchName: widget.profile.name,
        matchBio: _getBioFromPlatform() ?? '',
        platform: _selectedPlatform?.name ?? 'instagram',
        specificDetail: aiContext,
      );

      setState(() {
        _isGenerating = false;
        if (result.success && result.suggestions != null) {
          _suggestions = result.suggestions!;
        } else {
          _errorMessage = result.errorMessage ?? 'Erro ao gerar sugestões';
        }
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Erro ao gerar sugestões: $e';
      });
    }
  }

  /// Gera sugestões baseado apenas no texto digitado (sem análise de imagem)
  /// Usa o endpoint /reply que foca 100% na mensagem dela
  Future<void> _generateSuggestionsFromText() async {
    if (_lastMessage == null || _lastMessage!.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite a mensagem que ela enviou';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _suggestions = [];
    });

    try {
      final appState = Provider.of<AppState>(this.context, listen: false);
      final agentService = AgentService(baseUrl: appState.backendUrl);

      // Usa o endpoint /reply que foca APENAS na mensagem dela
      // Não passa contexto de perfil para evitar que a IA foque no perfil
      final result = await agentService.generateReply(
        receivedMessage: _lastMessage!.trim(),
        conversationHistory: null, // Pode adicionar histórico se necessário
      );

      setState(() {
        _isGenerating = false;
        final suggestions = result.suggestions ?? [];
        if (result.success && suggestions.isNotEmpty) {
          _suggestions = suggestions;
        } else {
          _errorMessage = result.errorMessage ?? 'Erro ao gerar sugestões';
        }
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Erro ao gerar sugestões: $e';
      });
    }
  }

  String? _getBioFromPlatform() {
    final platformData = widget.profile.platforms[_selectedPlatform];
    return platformData?.bio;
  }

  String _buildContextForAI() {
    final buffer = StringBuffer();

    // Info do perfil
    buffer.writeln('PERFIL: ${widget.profile.name}');

    // Dados da plataforma selecionada
    final platformData = widget.profile.platforms[_selectedPlatform];
    if (platformData != null) {
      if (platformData.bio != null) {
        buffer.writeln('Bio: ${platformData.bio}');
      }
      if (platformData.interests != null) {
        buffer.writeln('Interesses: ${platformData.interests!.join(", ")}');
      }
      if (platformData.photoDescriptions != null) {
        buffer.writeln('Fotos: ${platformData.photoDescriptions!.join(", ")}');
      }
    }

    // Contexto específico da ação
    if (_selectedAction == ActionType.responderStory && _selectedStory != null) {
      buffer.writeln('\nSTORY A RESPONDER:');
      buffer.writeln(_selectedStory!.description ?? 'Sem descrição');
    }

    if (_selectedAction == ActionType.responderOpeningMove) {
      final openingMove = widget.profile.platforms[PlatformType.bumble]?.openingMove;
      if (openingMove != null) {
        buffer.writeln('\nOPENING MOVE (pergunta dela):');
        buffer.writeln(openingMove);
      }
    }

    if (_lastMessage != null) {
      buffer.writeln('\nÚLTIMA MENSAGEM DELA:');
      buffer.writeln(_lastMessage);
    }

    return buffer.toString();
  }

  String _getActionTypeForAPI() {
    switch (_selectedAction) {
      case ActionType.primeiraDm:
      case ActionType.primeiraMensagem:
      case ActionType.primeiraEnviada:
        return 'opener';
      case ActionType.responderStory:
        return 'story_reply';
      case ActionType.responderOpeningMove:
        return 'opening_move_reply';
      case ActionType.continuarConversa:
      case ActionType.continuarConversaBumble:
      case ActionType.continuarConversaInstagram:
        return 'continuation';
      default:
        return 'opener';
    }
  }

  Future<void> _useSuggestion(String suggestion) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final conversationService = ConversationService(baseUrl: appState.backendUrl);

      // Obter dados da plataforma selecionada
      final platformData = widget.profile.platforms[_selectedPlatform];

      // Criar a conversa com a primeira mensagem
      final conversation = await conversationService.createConversation(
        matchName: widget.profile.name,
        username: platformData?.username,
        platform: _selectedPlatform?.name ?? 'outro',
        profileId: widget.profile.id,
        bio: platformData?.bio,
        photoDescriptions: platformData?.photoDescriptions,
        age: platformData?.age?.toString(),
        interests: platformData?.interests,
        firstMessage: suggestion,
        tone: 'expert',
        faceImageBase64: widget.profile.faceImageBase64,
        faceDescription: widget.profile.faceDescription,
      );

      setState(() {
        _isGenerating = false;
      });

      // Navegar para a tela de conversa
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conversation.id,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Erro ao criar conversa: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
