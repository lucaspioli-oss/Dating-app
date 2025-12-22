import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/conversation_service.dart';
import '../models/conversation.dart';

class ConversationDetailScreen extends StatefulWidget {
  final String conversationId;

  const ConversationDetailScreen({super.key, required this.conversationId});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  Conversation? _conversation;
  bool _isLoading = true;
  bool _isGeneratingSuggestions = false;

  final _receivedMessageController = TextEditingController();
  final _customMessageController = TextEditingController();
  List<String> _suggestions = [];
  String _analysisText = '';
  List<String> _responseOptions = [];

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _receivedMessageController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      final service = ConversationService(baseUrl: appState.backendUrl);
      final conversation = await service.getConversation(widget.conversationId);
      setState(() {
        _conversation = conversation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateSuggestions() async {
    if (_receivedMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite a mensagem recebida')),
      );
      return;
    }

    setState(() {
      _isGeneratingSuggestions = true;
      _suggestions = [];
      _analysisText = '';
      _responseOptions = [];
    });

    try {
      final appState = context.read<AppState>();
      final profileProvider = context.read<UserProfileProvider>();
      final service = ConversationService(baseUrl: appState.backendUrl);

      final suggestions = await service.generateSuggestions(
        conversationId: widget.conversationId,
        receivedMessage: _receivedMessageController.text.trim(),
        tone: 'expert',
        userContext: profileProvider.profile.isComplete
            ? {
                'name': profileProvider.profile.name,
                'age': profileProvider.profile.age,
                'interests': profileProvider.profile.interests,
                'dislikes': profileProvider.profile.dislikes,
                'humorStyle': profileProvider.profile.humorStyle,
                'relationshipGoal': profileProvider.profile.relationshipGoal,
              }
            : null,
      );

      // Parse suggestions to separate analysis from options
      final parsed = _parseSuggestions(suggestions);

      setState(() {
        _suggestions = suggestions;
        _analysisText = parsed['analysis'] ?? '';
        _responseOptions = List<String>.from(parsed['options'] ?? []);
        _isGeneratingSuggestions = false;
      });

      _receivedMessageController.clear();
      await _loadConversation();
    } catch (e) {
      setState(() => _isGeneratingSuggestions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _parseSuggestions(List<String> rawSuggestions) {
    final analysisLines = <String>[];
    final options = <String>[];

    for (final line in rawSuggestions) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();

      // Check if it's analysis/metadata
      final isAnalysis = trimmed.startsWith('---') ||
          trimmed.startsWith('**') ||
          lower.startsWith('análise') ||
          lower.startsWith('analise') ||
          lower.startsWith('contexto') ||
          lower.startsWith('tipo de mensagem') ||
          lower.contains('tipo de mensagem:') ||
          lower.startsWith('estratégia') ||
          lower.startsWith('estrategia') ||
          lower.startsWith('observação') ||
          lower.startsWith('observacao') ||
          lower.startsWith('dica') ||
          lower.startsWith('nota') ||
          RegExp(r'^opção\s*\d+', caseSensitive: false).hasMatch(lower) ||
          RegExp(r'^sugestão\s*\d+', caseSensitive: false).hasMatch(lower) ||
          (trimmed.contains(':') && trimmed.indexOf(':') < 20);

      if (isAnalysis) {
        // Clean up the line for analysis display
        String cleaned = trimmed
            .replaceAll(RegExp(r'^\*+|\*+$'), '')
            .replaceAll(RegExp(r'^-+|-+$'), '')
            .trim();
        if (cleaned.isNotEmpty) {
          analysisLines.add(cleaned);
        }
      } else {
        // It's an actual response option
        options.add(trimmed);
      }
    }

    return {
      'analysis': analysisLines.join('\n'),
      'options': options,
    };
  }

  Future<void> _sendMessage(String content, {bool wasAiSuggestion = false}) async {
    try {
      final appState = context.read<AppState>();
      final service = ConversationService(baseUrl: appState.backendUrl);

      await service.addMessage(
        conversationId: widget.conversationId,
        role: 'user',
        content: content,
        wasAiSuggestion: wasAiSuggestion,
        tone: wasAiSuggestion ? 'expert' : null,
      );

      setState(() {
        _suggestions = [];
        _analysisText = '';
        _responseOptions = [];
        _customMessageController.clear();
      });

      await _loadConversation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensagem registrada!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
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
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitFeedback(String messageId, bool gotResponse, String? quality) async {
    try {
      final appState = context.read<AppState>();
      final service = ConversationService(baseUrl: appState.backendUrl);

      await service.submitFeedback(
        conversationId: widget.conversationId,
        messageId: messageId,
        gotResponse: gotResponse,
        responseQuality: quality,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback registrado!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 1),
          ),
        );
        await _loadConversation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          title: const Text('Carregando...', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63))),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          title: const Text('Erro', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('Conversa não encontrada', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageHistory()),
          _buildInputSection(),
          if (_analysisText.isNotEmpty || _responseOptions.isNotEmpty) _buildSuggestionsSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A2A3E),
            child: Text(
              _conversation!.avatar.matchName.isNotEmpty
                  ? _conversation!.avatar.matchName[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _conversation!.avatar.matchName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                _conversation!.avatar.platform,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey),
          onPressed: _showAvatarInfo,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: _confirmDeleteConversation,
        ),
      ],
    );
  }

  Widget _buildMessageHistory() {
    return ListView.builder(
      reverse: false,
      padding: const EdgeInsets.all(16),
      itemCount: _conversation!.messages.length,
      itemBuilder: (context, index) {
        final message = _conversation!.messages[index];
        final isUser = message.role == 'user';
        final isLastUserMessage = isUser &&
            (index == _conversation!.messages.length - 1 ||
             _conversation!.messages.skip(index + 1).every((m) => m.role == 'user'));

        return _buildMessageBubble(message, isUser, isLastUserMessage);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isUser, bool showFeedback) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFFE91E63) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.grey.shade300,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (message.wasAiSuggestion == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: isUser ? Colors.white60 : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Sugestão IA',
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Feedback sutil abaixo da mensagem
        if (showFeedback && message.wasAiSuggestion == true)
          _buildSubtleFeedback(message.id),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSubtleFeedback(String messageId) {
    return Container(
      margin: const EdgeInsets.only(top: 4, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Ela respondeu?',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(width: 8),
          _buildFeedbackChip('❄️', messageId, true, 'cold'),
          const SizedBox(width: 4),
          _buildFeedbackChip('😐', messageId, true, 'neutral'),
          const SizedBox(width: 4),
          _buildFeedbackChip('🔥', messageId, true, 'warm'),
          const SizedBox(width: 4),
          _buildFeedbackChip('✕', messageId, false, null),
        ],
      ),
    );
  }

  Widget _buildFeedbackChip(String emoji, String messageId, bool gotResponse, String? quality) {
    return GestureDetector(
      onTap: () => _submitFeedback(messageId, gotResponse, quality),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A3E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A2A3E)),
              ),
              child: TextField(
                controller: _receivedMessageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cole a mensagem que ela enviou...',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isGeneratingSuggestions ? null : _generateSuggestions,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isGeneratingSuggestions
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A3E))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _suggestions = [];
                    _analysisText = '';
                    _responseOptions = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: Colors.grey, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analysis Section - plain text, no box
                  if (_analysisText.isNotEmpty) ...[
                    Text(
                      _analysisText,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Response Options Section
                  if (_responseOptions.isNotEmpty) ...[
                    Text(
                      'Sugestões de resposta:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_responseOptions.length, (index) {
                      return _buildSuggestionCard(index, _responseOptions[index]);
                    }),
                  ],
                ],
              ),
            ),
          ),
          // Custom message input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A3E)),
                    ),
                    child: TextField(
                      controller: _customMessageController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ou escreva sua própria...',
                        hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_customMessageController.text.trim().isNotEmpty) {
                      _sendMessage(_customMessageController.text.trim(), wasAiSuggestion: false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send, color: Colors.grey, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(int index, String suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE91E63),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copyToClipboard(suggestion),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _sendMessage(suggestion, wasAiSuggestion: true),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Excluir conversa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Excluir conversa com ${_conversation!.avatar.matchName}?',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final appState = context.read<AppState>();
        final service = ConversationService(baseUrl: appState.backendUrl);
        await service.deleteConversation(widget.conversationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversa excluída'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAvatarInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final avatar = _conversation!.avatar;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2A2A3E),
                    child: Text(
                      avatar.matchName.isNotEmpty ? avatar.matchName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avatar.matchName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        avatar.platform,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              if (avatar.bio != null && avatar.bio!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Bio', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 4),
                Text(avatar.bio!, style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
              ],
              const SizedBox(height: 20),
              Text('Analytics', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAnalyticChip('${avatar.analytics.totalMessages}', 'Mensagens'),
                  const SizedBox(width: 8),
                  _buildAnalyticChip('${avatar.analytics.aiSuggestionsUsed}', 'IA usadas'),
                  const SizedBox(width: 8),
                  _buildAnalyticChip(avatar.analytics.conversationQuality, 'Qualidade'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
        ],
      ),
    );
  }
}
