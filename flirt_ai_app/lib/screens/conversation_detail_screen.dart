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
  String? _selectedSuggestion;
  String _currentTone = 'casual';

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
        _currentTone = conversation.currentTone;
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
      _selectedSuggestion = null;
    });

    try {
      final appState = context.read<AppState>();
      final profileProvider = context.read<UserProfileProvider>();
      final service = ConversationService(baseUrl: appState.backendUrl);

      final suggestions = await service.generateSuggestions(
        conversationId: widget.conversationId,
        receivedMessage: _receivedMessageController.text.trim(),
        tone: _currentTone,
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

      setState(() {
        _suggestions = suggestions;
        _isGeneratingSuggestions = false;
      });

      // Limpar campo após gerar
      _receivedMessageController.clear();
      await _loadConversation(); // Recarregar para mostrar a mensagem recebida
    } catch (e) {
      setState(() => _isGeneratingSuggestions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        tone: wasAiSuggestion ? _currentTone : null,
      );

      setState(() {
        _suggestions = [];
        _selectedSuggestion = null;
        _customMessageController.clear();
      });

      await _loadConversation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Mensagem enviada!'), backgroundColor: Colors.green),
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
      const SnackBar(content: Text('📋 Copiado!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Conversa não encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation!.avatar.matchName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAvatarInfo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDeleteConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calibragem
          _buildCalibrationBar(),
          // Histórico
          Expanded(child: _buildMessageHistory()),
          // Input de nova mensagem recebida
          _buildInputSection(),
          // Sugestões
          if (_suggestions.isNotEmpty) _buildSuggestionsSection(),
        ],
      ),
    );
  }

  Widget _buildCalibrationBar() {
    final patterns = _conversation!.avatar.detectedPatterns;
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCalibrationChip(patterns.responseLengthEmoji, patterns.responseLength),
          _buildCalibrationChip(patterns.emotionalToneEmoji, patterns.emotionalTone),
          _buildCalibrationChip(patterns.flirtLevelEmoji, 'Flerte: ${patterns.flirtLevel}'),
          _buildCalibrationChip(_conversation!.avatar.analytics.qualityEmoji, 'Qualidade'),
        ],
      ),
    );
  }

  Widget _buildCalibrationChip(String emoji, String label) {
    return Chip(
      avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
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

        return Column(
          children: [
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                    if (message.wasAiSuggestion == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🤖 Sugestão da IA',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Botões de feedback para última mensagem enviada pelo usuário
            if (isLastUserMessage && message.wasAiSuggestion == true)
              _buildFeedbackButtons(message.id),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackButtons(String messageId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          const Text(
            '🧠 Ajude a IA a melhorar! Ela respondeu?',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeedbackChip('❄️ Fria', messageId, true, 'cold'),
              _buildFeedbackChip('😐 Neutra', messageId, true, 'neutral'),
              _buildFeedbackChip('🔥 Calorosa', messageId, true, 'warm'),
              _buildFeedbackChip('❌ Não', messageId, false, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackChip(String label, String messageId, bool gotResponse, String? quality) {
    return InkWell(
      onTap: () => _submitFeedback(messageId, gotResponse, quality),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
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
            content: Text('🧠 Feedback registrado! Obrigado por ajudar.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadConversation(); // Recarregar para remover botões
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mensagem Recebida:', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _receivedMessageController,
                    decoration: const InputDecoration(
                      hintText: 'Cole a mensagem...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isGeneratingSuggestions ? null : _generateSuggestions,
                  child: _isGeneratingSuggestions
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildToneSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildToneSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildToneChip('😄', 'Engraçado', 'engraçado'),
          _buildToneChip('❤️', 'Romântico', 'romântico'),
          _buildToneChip('😎', 'Casual', 'casual'),
          _buildToneChip('🔥', 'Ousado', 'ousado'),
          _buildToneChip('💪', 'Confiante', 'confiante'),
          _buildToneChip('🎯', 'Expert', 'expert'),
        ],
      ),
    );
  }

  Widget _buildToneChip(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Text(emoji),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: _currentTone == value,
        onSelected: (selected) {
          setState(() => _currentTone = value);
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(top: BorderSide(color: Colors.blue.shade200)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('💬 Sugestões:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _suggestions = [];
                      _selectedSuggestion = null;
                    });
                  },
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            final isSelected = _selectedSuggestion == suggestion;
            return Card(
              color: isSelected ? Colors.blue.shade100 : null,
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(suggestion),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(suggestion),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(suggestion, wasAiSuggestion: true),
                    ),
                  ],
                ),
                onTap: () => setState(() => _selectedSuggestion = suggestion),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          const Text('Ou escreva sua própria:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customMessageController,
                  decoration: const InputDecoration(
                    hintText: 'Sua mensagem customizada...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (_customMessageController.text.trim().isNotEmpty) {
                    _sendMessage(_customMessageController.text.trim(), wasAiSuggestion: false);
                  }
                },
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conversa'),
        content: Text('Excluir conversa com ${_conversation!.avatar.matchName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
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
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Voltar para lista de conversas
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
      builder: (context) {
        final avatar = _conversation!.avatar;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Perfil: ${avatar.matchName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              if (avatar.bio != null) Text('Bio: ${avatar.bio}'),
              if (avatar.age != null) Text('Idade: ${avatar.age}'),
              if (avatar.location != null) Text('Local: ${avatar.location}'),
              const SizedBox(height: 16),
              const Text('💡 Informações Aprendidas:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (avatar.learnedInfo.hobbies != null && avatar.learnedInfo.hobbies!.isNotEmpty)
                Text('Hobbies: ${avatar.learnedInfo.hobbies!.join(", ")}'),
              const SizedBox(height: 16),
              const Text('📈 Analytics:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total mensagens: ${avatar.analytics.totalMessages}'),
              Text('Sugestões IA usadas: ${avatar.analytics.aiSuggestionsUsed}'),
              Text('Mensagens customizadas: ${avatar.analytics.customMessagesUsed}'),
            ],
          ),
        );
      },
    );
  }
}
