import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../models/profile_model.dart';
import '../providers/app_state.dart';
import '../services/agent_service.dart';
import '../services/profile_service.dart';
import '../services/conversation_service.dart';
import '../models/conversation.dart';
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
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Perfil não encontrado',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            color: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditProfileDialog();
              } else if (value == 'context') {
                _showEditContextDialog();
              } else if (value == 'photos') {
                _showPhotosManager();
              } else if (value == 'delete') {
                _confirmDeleteProfile();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Editar Nome', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'context',
                child: Row(
                  children: [
                    Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Editar Contexto', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'photos',
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Gerenciar Fotos', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Excluir Perfil', style: TextStyle(color: Colors.red)),
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
              _buildContextSection(),
              const SizedBox(height: 20),
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
            colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.4),
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
    Uint8List? faceImageBytes;
    if (_profile!.faceImageBase64 != null) {
      try {
        faceImageBytes = base64Decode(_profile!.faceImageBase64!);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A2E),
              ),
              child: ClipOval(
                child: faceImageBytes != null
                    ? Image.memory(
                        faceImageBytes,
                        fit: BoxFit.cover,
                        width: 74,
                        height: 74,
                      )
                    : Container(
                        color: const Color(0xFF2A2A3E),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey.shade600,
                        ),
                      ),
              ),
            ),
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
                    color: Colors.white,
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

  Widget _buildContextSection() {
    final hasContext = _profile!.longTermContext != null || _profile!.shortTermContext != null;

    return GestureDetector(
      onTap: () => _showEditContextDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFFE91E63),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Contexto para IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  hasContext ? Icons.edit_outlined : Icons.add,
                  color: const Color(0xFF888888),
                  size: 20,
                ),
              ],
            ),
            if (!hasContext) ...[
              const SizedBox(height: 12),
              Text(
                'Adicione contexto sobre seu relacionamento para a IA gerar mensagens mais personalizadas',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
            if (_profile!.longTermContext != null && _profile!.longTermContext!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'HISTORIA',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _profile!.longTermContext!,
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_profile!.shortTermContext != null && _profile!.shortTermContext!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'OBJETIVO ATUAL',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _profile!.shortTermContext!,
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstagramSection() {
    final instagram = _profile!.instagram!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📸', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text(
                'Instagram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (instagram.username != null)
                Text(
                  '@${instagram.username}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
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
                color: Color(0xFFAAAAAA),
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
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addStory(),
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFFE91E63),
                ),
                label: const Text(
                  'Adicionar',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
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
            color: const Color(0xFF1A1A2E),
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
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A4E)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Color(0xFF888888),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Story',
              style: TextStyle(
                color: Color(0xFF888888),
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
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
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
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (datingApps.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${datingApps.length}',
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          iconColor: const Color(0xFF888888),
          collapsedIconColor: const Color(0xFF888888),
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
        color: const Color(0xFF2A2A3E),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (app.bio != null)
                  Text(
                    app.bio!,
                    style: const TextStyle(
                      color: Color(0xFF888888),
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
                      color: const Color(0xFFE91E63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Opening Move',
                      style: TextStyle(
                        color: Color(0xFFE91E63),
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
          color: const Color(0xFF2A2A3E),
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
              color: Color(0xFF888888),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Adicionar App',
              style: TextStyle(
                color: Color(0xFF888888),
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
                color: Color(0xFF888888),
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
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _conversationFilter ?? 'Todas',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFFAAAAAA),
                      size: 16,
                    ),
                  ],
                ),
              ),
              color: const Color(0xFF2A2A3E),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todas', style: TextStyle(color: Colors.white)),
                ),
                ..._profile!.platforms.keys.map((platform) {
                  return PopupMenuItem(
                    value: platform.name,
                    child: Text(
                      platform.displayName,
                      style: const TextStyle(color: Colors.white),
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
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE91E63)),
              );
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
                  color: const Color(0xFF1A1A2E),
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
                      'Nenhuma conversa ainda',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Peça uma sugestão para começar',
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
    Uint8List? faceImageBytes;
    if (_profile!.faceImageBase64 != null) {
      try {
        faceImageBytes = base64Decode(_profile!.faceImageBase64!);
      } catch (_) {}
    }

    final platformIcon = _getPlatformIcon(conv.platform);
    final platformColor = _getPlatformColor(conv.platform);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversationId: conv.id,
            ),
          ),
        ).then((_) => _loadProfile());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A1A2E),
                    ),
                    child: ClipOval(
                      child: faceImageBytes != null
                          ? Image.memory(
                              faceImageBytes,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                            )
                          : Container(
                              color: const Color(0xFF2A2A3E),
                              child: Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.grey.shade600,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: platformColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                    ),
                    child: Text(
                      platformIcon,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
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
                          color: Colors.white,
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
                    style: TextStyle(
                      color: Colors.grey.shade500,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestSuggestionScreen(profile: _profile!),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar story: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteStory(StoryData story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Excluir Story?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _profileService.removeStory(widget.profileId, story.id);
              await _loadProfile();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
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
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(
          'Remover ${type.displayName}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Os dados desta plataforma serão removidos.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _profileService.removePlatform(widget.profileId, type);
              await _loadProfile();
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
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
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Excluir Perfil?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'O perfil e todas as conversas serão excluídos permanentemente.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _profileService.deleteProfile(widget.profileId);
              Navigator.pop(context);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as plataformas já foram adicionadas'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
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
                  color: Colors.white,
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
                        color: const Color(0xFF2A2A3E),
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
                            style: const TextStyle(color: Colors.white),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar plataforma: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profile!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Editar Nome',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nome do perfil',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3A3A4E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3A3A4E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE91E63)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                await _profileService.updateProfileName(widget.profileId, newName);
                await _loadProfile();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nome atualizado!'),
                    backgroundColor: Color(0xFFE91E63),
                  ),
                );
              }
            },
            child: const Text(
              'Salvar',
              style: TextStyle(color: Color(0xFFE91E63)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditContextDialog() {
    final longTermController = TextEditingController(text: _profile!.longTermContext ?? '');
    final shortTermController = TextEditingController(text: _profile!.shortTermContext ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
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
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Color(0xFFE91E63),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Contexto para IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A IA usara essas informacoes para gerar mensagens mais personalizadas',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'HISTORIA DO RELACIONAMENTO',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: longTermController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: Ela e minha amiga de infancia, nos conhecemos na escola...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'OBJETIVO ATUAL',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: shortTermController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: Quero sair da friendzone e chamar ela pra sair...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _profileService.updateProfileContext(
                          widget.profileId,
                          longTermContext: longTermController.text.trim(),
                          shortTermContext: shortTermController.text.trim(),
                        );
                        await _loadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contexto salvo!'),
                            backgroundColor: Color(0xFFE91E63),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Salvar Contexto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotosManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Gerenciar Fotos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Foto principal do perfil
                    if (_profile!.faceImageBase64 != null) ...[
                      const Text(
                        'FOTO PRINCIPAL',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPhotoItem(
                        imageBase64: _profile!.faceImageBase64!,
                        label: 'Foto do Perfil',
                        onDelete: () => _confirmDeleteFaceImage(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Fotos por plataforma
                    ..._profile!.platforms.entries.map((entry) {
                      final platform = entry.key;
                      final data = entry.value;
                      final hasImages = data.profileImageBase64 != null ||
                          (data.profileImagesBase64 != null && data.profileImagesBase64!.isNotEmpty);

                      if (!hasImages) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${platform.icon} ${platform.displayName.toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (data.profileImageBase64 != null)
                            _buildPhotoItem(
                              imageBase64: data.profileImageBase64!,
                              label: 'Foto Principal',
                              onDelete: () => _confirmDeletePlatformImage(platform),
                            ),
                          if (data.profileImagesBase64 != null)
                            ...data.profileImagesBase64!.asMap().entries.map((imageEntry) {
                              return _buildPhotoItem(
                                imageBase64: imageEntry.value,
                                label: 'Foto ${imageEntry.key + 1}',
                                onDelete: () => _confirmDeleteProfileImage(platform, imageEntry.key),
                              );
                            }),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem({
    required String imageBase64,
    required String label,
    required VoidCallback onDelete,
  }) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(imageBase64);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageBytes != null
                ? Image.memory(
                    imageBytes,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFF3A3A4E),
                    child: const Icon(
                      Icons.image,
                      color: Color(0xFF666666),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFaceImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Excluir Foto Principal?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'A foto principal do perfil será removida.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // Fecha o modal de fotos
              await _profileService.updateProfileFaceImage(widget.profileId, null);
              await _loadProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto removida'),
                  backgroundColor: Color(0xFFE91E63),
                ),
              );
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlatformImage(PlatformType platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(
          'Excluir Foto de ${platform.displayName}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta foto será removida.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // Fecha o modal de fotos
              await _profileService.removePlatformMainImage(widget.profileId, platform);
              await _loadProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto removida'),
                  backgroundColor: Color(0xFFE91E63),
                ),
              );
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProfileImage(PlatformType platform, int imageIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Excluir Foto?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta foto será removida do perfil.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // Fecha o modal de fotos
              await _profileService.removeProfileImage(widget.profileId, platform, imageIndex);
              await _loadProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto removida'),
                  backgroundColor: Color(0xFFE91E63),
                ),
              );
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
