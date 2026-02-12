import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import '../config/app_theme.dart';
import '../config/app_haptics.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/conversation_service.dart';
import '../services/agent_service.dart';
import '../services/subscription_service.dart';
import '../models/conversation.dart';
import '../widgets/app_loading.dart';
import '../widgets/profile_avatar.dart';

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

  final _messageInputController = TextEditingController();
  final _herMessageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<String> _suggestions = [];
  String _analysisText = '';
  List<String> _responseOptions = [];

  // Developer mode
  bool _isDeveloper = false;
  final _feedbackNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversation();
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
    _messageInputController.dispose();
    _herMessageController.dispose();
    _feedbackNoteController.dispose();
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
        AppHaptics.error();
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // GENERATE SUGGESTIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  void _showGenerateOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.messageInputQuestion,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.messageInputInfo,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Upload screenshot
              _buildOptionTile(
                icon: Icons.photo_camera,
                title: AppLocalizations.of(context)!.uploadScreenshotTitle,
                subtitle: AppLocalizations.of(context)!.uploadScreenshotSubtitle,
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndAnalyzeImage();
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Type message
              _buildOptionTile(
                icon: Icons.keyboard,
                title: AppLocalizations.of(context)!.typeMessageTitle,
                subtitle: AppLocalizations.of(context)!.typeMessageSubtitle,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  _showTypeMessageDialog();
                },
              ),
              const SizedBox(height: 12),

              // Option 3: Import WhatsApp conversation
              _buildOptionTile(
                icon: Icons.chat,
                title: AppLocalizations.of(context)!.importWhatsAppTitle,
                subtitle: AppLocalizations.of(context)!.importWhatsAppSubtitle,
                color: const Color(0xFF25D366),
                onTap: () {
                  Navigator.pop(context);
                  _showImportWhatsAppDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Show loading dialog while analyzing
      if (!mounted) return;
      _showAnalyzingDialog(bytes);

      // Call OCR endpoint
      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeConversationImage(
        imageBase64: base64Image,
        platform: _conversation?.avatar.platform,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (result.success && result.lastMessage != null && result.lastMessage!.isNotEmpty) {
        // Pre-fill with extracted message
        _showImageWithMessageInput(bytes, extractedMessage: result.lastMessage);
      } else {
        // OCR failed, let user type manually
        _showImageWithMessageInput(bytes, errorMessage: result.errorMessage ?? 'NÃ£o foi possÃ­vel extrair o texto');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/conversation');
      }
      if (mounted) {
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }

  void _showAnalyzingDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show thumbnail
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.analyzingImageText,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.extractingTextInfo,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageWithMessageInput(Uint8List imageBytes, {String? extractedMessage, String? errorMessage}) {
    _herMessageController.text = extractedMessage ?? '';
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          extractedMessage != null ? l10n.confirmMessage : l10n.typeTheMessage,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show the image
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.elevatedDark),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.memory(imageBytes, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              if (extractedMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        l10n.textExtractedAutomatically,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.typeManually,
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                extractedMessage != null
                  ? l10n.editIfNeeded
                  : l10n.typeLastMessageSent,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _herMessageController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                autofocus: extractedMessage == null,
                decoration: InputDecoration(
                  hintText: l10n.pasteOrTypeMessage,
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_herMessageController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _generateSuggestionsFromText(_herMessageController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.generateSuggestionsButton, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showTypeMessageDialog() {
    _herMessageController.clear();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          l10n.whatSheSaid,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.pasteOrTypeLastMessage,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _herMessageController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.messageExampleHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_herMessageController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _generateSuggestionsFromText(_herMessageController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.generateSuggestionsButton, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showImportWhatsAppDialog() {
    final chatController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          l10n.importConversationTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.whatsappInstructions,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: chatController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                maxLines: 8,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: l10n.pasteConversationHint,
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = chatController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                _importWhatsAppChat(text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.importButton, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _importWhatsAppChat(String chatText) async {
    final matchName = _conversation?.avatar.matchName ?? '';

    // Parse WhatsApp messages
    final parsed = _parseWhatsAppChat(chatText, matchName);

    if (parsed.isEmpty) {
      if (mounted) {
        AppSnackBar.error(context, 'Nenhuma mensagem encontrada. Verifique o formato.');
      }
      return;
    }

    // Show progress
    setState(() => _isGeneratingSuggestions = true);

    try {
      final appState = context.read<AppState>();
      final service = ConversationService(baseUrl: appState.backendUrl);

      // Add messages in order
      for (final msg in parsed) {
        await service.addMessage(
          conversationId: widget.conversationId,
          role: msg['role']!,
          content: msg['content']!,
        );
      }

      await _loadConversation();

      setState(() => _isGeneratingSuggestions = false);

      if (mounted) {
        AppSnackBar.success(context, '${parsed.length} mensagens importadas!');
      }
    } catch (e) {
      setState(() => _isGeneratingSuggestions = false);
      if (mounted) {
        AppHaptics.error();
        AppSnackBar.error(context, 'Erro ao importar: $e');
      }
    }
  }

  List<Map<String, String>> _parseWhatsAppChat(String text, String matchName) {
    final messages = <Map<String, String>>[];
    final lines = text.split('\n');

    // WhatsApp export formats:
    // [DD/MM/YYYY, HH:MM:SS] Name: message
    // DD/MM/YYYY, HH:MM - Name: message
    // DD/MM/YY HH:MM - Name: message
    final regexBracket = RegExp(r'^\[(\d{1,2}/\d{1,2}/\d{2,4}),?\s+\d{1,2}:\d{2}(?::\d{2})?\]\s+([^:]+):\s*(.+)');
    final regexDash = RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4},?\s+\d{1,2}:\d{2}(?::\d{2})?\s*[-â€“]\s*([^:]+):\s*(.+)');

    // Detect all participant names first
    final names = <String>{};
    for (final line in lines) {
      final m1 = regexBracket.firstMatch(line);
      if (m1 != null) {
        names.add(m1.group(2)!.trim());
        continue;
      }
      final m2 = regexDash.firstMatch(line);
      if (m2 != null) {
        names.add(m2.group(1)!.trim());
      }
    }

    // Determine which name is the match (fuzzy match)
    String? matchDetected;
    final matchLower = matchName.toLowerCase();
    for (final name in names) {
      if (name.toLowerCase().contains(matchLower) || matchLower.contains(name.toLowerCase())) {
        matchDetected = name;
        break;
      }
    }

    // If no fuzzy match, pick the name that isn't the majority sender (heuristic: the other person)
    if (matchDetected == null && names.length == 2) {
      matchDetected = names.first;
    }

    // Parse messages with multiline support
    String? currentRole;
    String? currentContent;

    for (final line in lines) {
      String? sender;
      String? content;

      final m1 = regexBracket.firstMatch(line);
      if (m1 != null) {
        sender = m1.group(2)!.trim();
        content = m1.group(3)!.trim();
      } else {
        final m2 = regexDash.firstMatch(line);
        if (m2 != null) {
          sender = m2.group(1)!.trim();
          content = m2.group(2)!.trim();
        }
      }

      if (sender != null && content != null) {
        // Save previous message
        if (currentRole != null && currentContent != null && currentContent!.isNotEmpty) {
          // Skip system messages
          if (!currentContent!.contains('mensagens e chamadas sÃ£o protegidas') &&
              !currentContent!.contains('criou este grupo') &&
              currentContent != '<MÃ­dia oculta>') {
            messages.add({'role': currentRole!, 'content': currentContent!});
          }
        }

        currentRole = (sender == matchDetected) ? 'match' : 'user';
        currentContent = content;
      } else if (currentContent != null && line.trim().isNotEmpty) {
        // Continuation of previous message
        currentContent = '$currentContent\n${line.trim()}';
      }
    }

    // Save last message
    if (currentRole != null && currentContent != null && currentContent!.isNotEmpty) {
      if (!currentContent!.contains('mensagens e chamadas sÃ£o protegidas') &&
          !currentContent!.contains('criou este grupo') &&
          currentContent != '<MÃ­dia oculta>') {
        messages.add({'role': currentRole!, 'content': currentContent!});
      }
    }

    return messages;
  }

  Future<void> _generateSuggestionsFromText(String herMessage) async {
    setState(() {
      _isGeneratingSuggestions = true;
      _suggestions = [];
      _analysisText = '';
      _responseOptions = [];
    });

    try {
      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      // Use the reply endpoint that focuses on her message
      final result = await agentService.generateReply(
        receivedMessage: herMessage,
        conversationHistory: _conversation?.messages.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
      );

      setState(() {
        _suggestions = result.suggestions ?? [];
        _responseOptions = result.suggestions ?? [];
        _isGeneratingSuggestions = false;
      });

      // Save her message to conversation history
      if (_conversation != null) {
        final service = ConversationService(baseUrl: appState.backendUrl);
        await service.addMessage(
          conversationId: widget.conversationId,
          role: 'match',
          content: herMessage,
        );
        await _loadConversation();
      }
    } catch (e) {
      setState(() => _isGeneratingSuggestions = false);
      if (mounted) {
        AppHaptics.error();
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }

  Future<void> _sendMessage(String content, {bool wasAiSuggestion = false}) async {
    AppHaptics.lightImpact();
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
        _messageInputController.clear();
      });

      await _loadConversation();

      if (mounted) {
        AppSnackBar.success(context, AppLocalizations.of(context)!.messageSavedSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppHaptics.error();
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppHaptics.success();
    AppSnackBar.success(context, AppLocalizations.of(context)!.copiedNotification);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // BUILD UI
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(AppLocalizations.of(context)!.loadingTitle, style: const TextStyle(color: AppColors.textPrimary)),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: const AppLoading(),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(AppLocalizations.of(context)!.errorTitle, style: const TextStyle(color: AppColors.textPrimary)),
        ),
        body: Center(child: Text(AppLocalizations.of(context)!.conversationNotFound, style: const TextStyle(color: AppColors.textPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageHistory()),
          if (_responseOptions.isNotEmpty) _buildSuggestionsSection(),
          _buildInputSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final avatar = _conversation!.avatar;
    final displayName = avatar.platform == 'instagram' && avatar.username != null
        ? '@${avatar.username}'
        : avatar.matchName;
    final displaySubtitle = avatar.age != null
        ? '${avatar.platform}, ${avatar.age} anos'
        : avatar.platform;

    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildAvatarImage(avatar, 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                displaySubtitle,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: AppColors.textTertiary),
          onPressed: _showAvatarInfo,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: _confirmDeleteConversation,
        ),
      ],
    );
  }

  Widget _buildAvatarImage(ConversationAvatar avatar, double radius) {
    return ProfileAvatar(
      imageUrl: avatar.faceImageUrl,
      name: avatar.matchName,
      size: radius * 2,
      borderWidth: radius > 20 ? 2.5 : 2,
      showShadow: radius > 20,
    );
  }

  Widget _buildMessageHistory() {
    if (_conversation!.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textTertiary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.emptyConversationTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.emptyConversationInfo,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: false,
      padding: const EdgeInsets.all(16),
      itemCount: _conversation!.messages.length,
      itemBuilder: (context, index) {
        final message = _conversation!.messages[index];
        final isUser = message.role == 'user';
        final isMatch = message.role == 'match';

        return _buildMessageBubble(message, isUser, isMatch);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isUser, bool isMatch) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primary
                : isMatch
                    ? AppColors.elevatedDark
                    : AppColors.surfaceDark,
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
              if (isMatch)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    AppLocalizations.of(context)!.sheSaidLabel,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? AppColors.textPrimary : AppColors.textSecondary,
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
                      Icon(Icons.auto_awesome, size: 12, color: isUser ? AppColors.textPrimary.withOpacity(0.6) : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.aiSuggestionLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? AppColors.textPrimary.withOpacity(0.6) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.elevatedDark)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Magic button - generate suggestions
            GestureDetector(
              onTap: _isGeneratingSuggestions ? null : _showGenerateOptionsMenu,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
            const SizedBox(width: 12),

            // Text input for direct message
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.elevatedDark),
                ),
                child: TextField(
                  controller: _messageInputController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.messageInputPlaceholder,
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: () {
                if (_messageInputController.text.trim().isNotEmpty) {
                  _sendMessage(_messageInputController.text.trim(), wasAiSuggestion: false);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.elevatedDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.send, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.elevatedDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFFFD93D), size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.suggestionsHeader,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _suggestions = [];
                    _responseOptions = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: AppColors.textTertiary, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // Suggestions list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: _responseOptions.length,
              itemBuilder: (context, index) {
                return _buildSuggestionCard(index, _responseOptions[index]);
              },
            ),
          ),

          // Developer feedback
          if (_isDeveloper)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildDeveloperFeedbackSection(),
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
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.elevatedDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Copy button
              GestureDetector(
                onTap: () => _copyToClipboard(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.elevatedDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.copyButtonText,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Use button
              GestureDetector(
                onTap: () {
                  AppHaptics.mediumImpact();
                  _sendMessage(suggestion, wasAiSuggestion: true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF5722)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.useButtonText,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DIALOGS AND INFO
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> _confirmDeleteConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(l10n.deleteConversationTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${l10n.deleteConversationConfirm} ${_conversation!.avatar.matchName}?',
          style: const TextStyle(color: AppColors.textTertiary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteButton),
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
          AppSnackBar.success(context, 'Conversa excluÃ­da');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppHaptics.error();
          AppSnackBar.error(context, 'Erro: $e');
        }
      }
    }
  }

  void _showAvatarInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final avatar = _conversation!.avatar;
        final l10n = AppLocalizations.of(context)!;
        final displayName = avatar.platform == 'instagram' && avatar.username != null
            ? '@${avatar.username}'
            : avatar.matchName;
        final displaySubtitle = avatar.age != null
            ? '${avatar.platform}, ${avatar.age} anos'
            : avatar.platform;

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
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildAvatarImage(avatar, 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          displaySubtitle,
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (avatar.bio != null && avatar.bio!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(l10n.bioLabel, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(avatar.bio!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.analyticsLabel, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAnalyticChip('${avatar.analytics.totalMessages}', l10n.messagesAnalytic),
                  const SizedBox(width: 8),
                  _buildAnalyticChip('${avatar.analytics.aiSuggestionsUsed}', l10n.aiSuggestionsAnalytic),
                  const SizedBox(width: 8),
                  _buildAnalyticChip(avatar.analytics.conversationQuality, l10n.qualityAnalytic),
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
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.elevatedDark),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DEVELOPER FEEDBACK
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildDeveloperFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8B5CF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Feedback das sugestÃµes',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDevFeedbackButton('Bom', Icons.thumb_up, AppColors.success, () => _submitDevFeedback('good'))),
              const SizedBox(width: 6),
              Expanded(child: _buildDevFeedbackButton('Parcial', Icons.thumbs_up_down, AppColors.warning, () => _submitDevFeedback('partial'))),
              const SizedBox(width: 6),
              Expanded(child: _buildDevFeedbackButton('Ruim', Icons.thumb_down, AppColors.error, () => _submitDevFeedback('bad'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevFeedbackButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDevFeedback(String type) async {
    final appState = context.read<AppState>();
    final agentService = AgentService(baseUrl: appState.backendUrl);

    final inputData = {
      'action': 'conversation_continue',
      'matchName': _conversation?.avatar.matchName ?? '',
      'platform': _conversation?.avatar.platform ?? '',
      'conversationId': widget.conversationId,
    };

    final suggestionsData = _responseOptions.map((s) => {'text': s}).toList();

    final success = await agentService.submitDeveloperFeedback(
      inputData: inputData,
      analysis: null,
      suggestions: suggestionsData,
      feedbackType: type,
      feedbackNote: null,
    );

    if (mounted) {
      if (success) {
        AppSnackBar.success(context, 'Feedback enviado!');
      } else {
        AppSnackBar.error(context, 'Erro ao enviar');
      }
    }
  }
}
