import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import '../config/app_theme.dart';
import '../config/app_page_transitions.dart';
import '../config/app_haptics.dart';
import '../providers/app_state.dart';
import '../providers/user_profile_provider.dart';
import '../services/conversation_service.dart';
import '../models/conversation.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_empty_state.dart';
import 'conversation_detail_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationListItem> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      final service = ConversationService(baseUrl: appState.backendUrl);
      final conversations = await service.listConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppSnackBar.error(context, 'Erro: ${e.toString()}');
      }
    }
  }

  void _openConversation(ConversationListItem item) {
    AppHaptics.lightImpact();
    Navigator.push(
      context,
      FadeSlideRoute(page: ConversationDetailScreen(conversationId: item.id)),
    ).then((_) => _loadConversations()); // Recarregar ao voltar
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return AppLocalizations.of(context)!.yesterdayLabel;
    } else if (diff.inDays < 7) {
      return '${diff.inDays}${AppLocalizations.of(context)!.daysAgoLabel}';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💬 ${AppLocalizations.of(context)!.conversationsTitle}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoading())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.chat_bubble_outline,
      title: AppLocalizations.of(context)!.noConversationsTitle,
      description: AppLocalizations.of(context)!.noConversationsDescription,
    );
  }

  Widget _buildConversationTile(ConversationListItem conv) {
    final emotionalToneEmoji = conv.avatar['emotionalTone'] == 'warm'
        ? '🔥'
        : conv.avatar['emotionalTone'] == 'cold'
            ? '❄️'
            : '😐';

    return Dismissible(
      key: Key(conv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: AppColors.textPrimary),
      ),
      confirmDismiss: (direction) => _confirmDelete(conv),
      onDismissed: (direction) => _deleteConversation(conv.id),
      child: ListTile(
        leading: _buildAvatar(conv),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conv.displayNameWithAge,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(emotionalToneEmoji),
          ],
        ),
        subtitle: Text(
          conv.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(conv.lastMessageAt),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () => _confirmAndDelete(conv),
            ),
          ],
        ),
        onTap: () => _openConversation(conv),
      ),
    );
  }

  Widget _buildAvatar(ConversationListItem conv) {
    return ProfileAvatar(
      imageUrl: conv.faceImageUrl,
      name: conv.matchName,
      size: 48,
      borderWidth: 2,
      showShadow: false,
      badge: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(conv.platformEmoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<bool> _confirmDelete(ConversationListItem conv) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConversationTitle),
        content: Text('${l10n.deleteConversationConfirm} ${conv.matchName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _confirmAndDelete(ConversationListItem conv) async {
    final confirmed = await _confirmDelete(conv);
    if (confirmed) {
      await _deleteConversation(conv.id);
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      final appState = context.read<AppState>();
      final service = ConversationService(baseUrl: appState.backendUrl);
      await service.deleteConversation(conversationId);

      setState(() {
        _conversations.removeWhere((c) => c.id == conversationId);
      });

      if (mounted) {
        AppSnackBar.success(context, 'Conversa excluída');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }
}
