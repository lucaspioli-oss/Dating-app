import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../config/app_theme.dart';
import '../config/app_page_transitions.dart';
import '../config/app_haptics.dart';
import '../models/profile_model.dart';
import '../providers/app_state.dart';
import '../services/agent_service.dart';
import '../services/profile_service.dart';
import '../services/conversation_service.dart';
import '../models/conversation.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_empty_state.dart';
import 'request_suggestion_screen.dart';
import 'conversation_detail_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String profileId;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final ProfileService _profileService = ProfileService();
  final ConversationService _conversationService = ConversationService();
  final ImagePicker _picker = ImagePicker();

  Profile? _profile;
  bool _isLoading = true;
  bool _isDatingAppsExpanded = false;
  String? _conversationFilter;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile(widget.profileId);
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
        ),
        body: const Center(
          child: AppLoading(),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'Perfil não encontrado',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary, size: 22),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteProfile();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text('Excluir Perfil', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              if (_profile!.hasInstagram) ...[
                _buildInstagramSection(),
                const SizedBox(height: 20),
              ],
              _buildDatingAppsSection(),
              const SizedBox(height: 28),
              _buildConversationsSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _navigateToRequestSuggestion(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Nova Sugestão',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ProfileAvatar.fromBase64(
            base64Image: _profile!.faceImageBase64,
            name: _profile!.name,
            size: 80,
            borderWidth: 3,
            heroTag: 'profile_avatar_${_profile!.id}',
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _profile!.platforms.keys.map((platform) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(platform.name).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        platform.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
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

  Widget _buildInstagramSection() {
    final instagram = _profile!.instagram!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.elevatedDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\uD83D\uDCF8', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text(
                'Instagram',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (instagram.username != null)
                Text(
                  '@${instagram.username}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          if (instagram.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              instagram.bio!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stories',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addStory(),
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Adicionar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._profile!.stories.map((story) => _buildStoryItem(story)),
                _buildAddStoryButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(StoryData story) {
    Uint8List? imageBytes;
    if (story.imageBase64 != null) {
      try {
        imageBytes = base64Decode(story.imageBase64!);
      } catch (_) {}
    }

    return GestureDetector(
      onLongPress: () => _confirmDeleteStory(story),
      child: Container(
        width: 70,
        height: 70,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
            ],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surfaceDark,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageBytes != null
                ? Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.image,
                      color: Color(0xFF666666),
                      size: 24,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return GestureDetector(
      onTap: () => _addStory(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.elevatedDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A4E)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppColors.textTertiary,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Story',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatingAppsSection() {
    final datingApps = _profile!.datingApps;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.elevatedDark),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isDatingAppsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isDatingAppsExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              const Text(
                'Apps de Relacionamento',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (datingApps.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${datingApps.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          iconColor: AppColors.textTertiary,
          collapsedIconColor: AppColors.textTertiary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  ...datingApps.map((app) => _buildDatingAppItem(app)),
                  const SizedBox(height: 8),
                  _buildAddPlatformButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatingAppItem(PlatformData app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevatedDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(app.type.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.type.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (app.bio != null)
                  Text(
                    app.bio!,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (app.openingMove != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Opening Move',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFF666666),
              size: 20,
            ),
            onPressed: () => _confirmDeletePlatform(app.type),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlatformButton() {
    return GestureDetector(
      onTap: () => _showAddPlatformDialog(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.elevatedDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF3A3A4E),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppColors.textTertiary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Adicionar App',
              style: TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CONVERSAS',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            PopupMenuButton<String?>(
              initialValue: _conversationFilter,
              onSelected: (value) {
                setState(() {
                  _conversationFilter = value;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.elevatedDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _conversationFilter ?? 'Todas',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              color: AppColors.elevatedDark,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todas', style: TextStyle(color: AppColors.textPrimary)),
                ),
                ..._profile!.platforms.keys.map((platform) {
                  return PopupMenuItem(
                    value: platform.name,
                    child: Text(
                      platform.displayName,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder(
          stream: _conversationService.getConversationsForProfile(widget.profileId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerConversationList();
            }

            final conversations = snapshot.data ?? [];

            final filtered = _conversationFilter == null
                ? conversations
                : conversations
                    .where((c) => c.platform == _conversationFilter)
                    .toList();

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF666666),
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Comece a conversa',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Peca uma sugestao ou use o teclado',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filtered.map((conv) {
                return _buildConversationTile(conv);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversationTile(ConversationListItem conv) {
    final platformIcon = _getPlatformIcon(conv.platform);
    final platformColor = _getPlatformColor(conv.platform);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlideRoute(
            page: ConversationDetailScreen(
              conversationId: conv.id,
            ),
          ),
        ).then((_) => _loadProfile());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.elevatedDark),
        ),
        child: Row(
          children: [
            ProfileAvatar.fromBase64(
              base64Image: _profile!.faceImageBase64,
              name: _profile!.name,
              size: 52,
              borderWidth: 2,
              showShadow: false,
              badge: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: platformColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceDark, width: 2),
                ),
                child: Text(
                  platformIcon,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getPlatformDisplayName(conv.platform),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: platformColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          platformIcon,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv.lastMessage.isNotEmpty ? conv.lastMessage : 'Toque para ver a conversa',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF555555),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _getPlatformDisplayName(String? platform) {
    if (platform == null) return 'Conversa';
    try {
      final type = PlatformType.values.firstWhere(
        (e) => e.name == platform,
        orElse: () => PlatformType.outro,
      );
      return type.displayName;
    } catch (_) {
      return platform;
    }
  }

  Color _getPlatformColor(String? platform) {
    if (platform == null) return const Color(0xFF6B7280);
    switch (platform) {
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'tinder':
        return const Color(0xFFFF6B6B);
      case 'bumble':
        return const Color(0xFFFFD93D);
      case 'hinge':
        return const Color(0xFF8B5CF6);
      case 'happn':
        return const Color(0xFFFF9500);
      case 'innerCircle':
        return const Color(0xFF1E88E5);
      case 'whatsapp':
        return const Color(0xFF25D366);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getPlatformIcon(String? platform) {
    if (platform == null) return '💬';
    try {
      final type = PlatformType.values.firstWhere(
        (e) => e.name == platform,
        orElse: () => PlatformType.outro,
      );
      return type.icon;
    } catch (_) {
      return '💬';
    }
  }

  void _navigateToRequestSuggestion() {
    AppHaptics.mediumImpact();
    Navigator.push(
      context,
      ScaleFadeRoute(page: RequestSuggestionScreen(profile: _profile!)),
    );
  }

  Future<void> _addStory() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final originalBytes = await image.readAsBytes();
      final bytes = await _compressImage(originalBytes, maxSize: 800, quality: 50);
      final base64Image = base64Encode(bytes);
      const mediaType = 'image/jpeg';

      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeProfileImage(
        imageBase64: base64Image,
        platform: 'instagram',
        imageMediaType: mediaType,
      );

      final story = StoryData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageBase64: base64Image,
        description: result.bio ?? result.additionalInfo,
        createdAt: DateTime.now(),
      );

      await _profileService.addStory(widget.profileId, story);
      await _loadProfile();
    } catch (e) {
      AppSnackBar.error(context, 'Erro ao adicionar story: $e');
    }
  }

  void _confirmDeleteStory(StoryData story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedDark,
        title: const Text(
          'Excluir Story?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              AppHaptics.heavyImpact();
              Navigator.pop(context);
              await _profileService.removeStory(widget.profileId, story.id);
              await _loadProfile();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlatform(PlatformType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedDark,
        title: Text(
          'Remover ${type.displayName}?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Os dados desta plataforma serão removidos.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              AppHaptics.heavyImpact();
              Navigator.pop(context);
              await _profileService.removePlatform(widget.profileId, type);
              await _loadProfile();
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevatedDark,
        title: const Text(
          'Excluir Perfil?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'O perfil e todas as conversas serão excluídos permanentemente.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              AppHaptics.heavyImpact();
              Navigator.pop(context);
              await _profileService.deleteProfile(widget.profileId);
              Navigator.pop(context);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlatformDialog() {
    final existingPlatforms = _profile!.platforms.keys.toSet();
    final availablePlatforms = PlatformType.values
        .where((p) => p.isDatingApp && !existingPlatforms.contains(p))
        .toList();

    if (availablePlatforms.isEmpty) {
      AppSnackBar.info(context, 'Todas as plataformas já foram adicionadas');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adicionar Plataforma',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availablePlatforms.map((platform) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _addPlatform(platform);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            platform.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            platform.displayName,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPlatform(PlatformType platform) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final originalBytes = await image.readAsBytes();
      final bytes = await _compressImage(originalBytes, maxSize: 800, quality: 50);
      final base64Image = base64Encode(bytes);
      const mediaType = 'image/jpeg';

      final appState = context.read<AppState>();
      final agentService = AgentService(baseUrl: appState.backendUrl);

      final result = await agentService.analyzeProfileImage(
        imageBase64: base64Image,
        platform: platform.name,
        imageMediaType: mediaType,
      );

      final platformData = PlatformData(
        type: platform,
        bio: result.bio,
        age: result.age,
        location: result.location,
        occupation: result.occupation,
        interests: result.interests,
        photoDescriptions: result.photoDescriptions,
        profileImageBase64: base64Image,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileService.addPlatform(widget.profileId, platformData);
      await _loadProfile();
    } catch (e) {
      AppSnackBar.error(context, 'Erro ao adicionar plataforma: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes, {int maxSize = 800, int quality = 50}) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      img.Image resized;
      if (image.width > maxSize || image.height > maxSize) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: maxSize);
        } else {
          resized = img.copyResize(image, height: maxSize);
        }
      } else {
        resized = image;
      }

      final compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      return bytes;
    }
  }
}
