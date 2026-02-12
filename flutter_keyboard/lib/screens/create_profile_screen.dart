import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../models/profile_model.dart';
import '../providers/app_state.dart';
import '../services/agent_service.dart';
import '../services/profile_service.dart';
import 'profile_detail_screen.dart';

enum InstagramUploadMode { none, generalScreenshot, individualPhotos }

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = ProfileService();

  // Lista de plataformas adicionadas
  List<_PlatformEntry> _platformEntries = [];

  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final entry in _platformEntries) {
      entry.nameController.dispose();
      entry.bioController.dispose();
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Novo Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isAnalyzing ? _buildAnalyzingState() : _buildForm(),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE91E63).withOpacity(0.2),
                  const Color(0xFFFF5722).withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Analisando perfil...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Extraindo informações das imagens',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Se não tem nenhuma plataforma, mostrar seletor
        if (_platformEntries.isEmpty) ...[
          const Text(
            'Selecione a rede social',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Onde você conheceu essa pessoa?',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          _buildPlatformGrid(onSelect: _addPlatform),
        ],

        // Lista de plataformas adicionadas
        ..._platformEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final platformEntry = entry.value;
          return _buildPlatformSection(index, platformEntry);
        }),

        // Botão de adicionar outra rede social
        if (_platformEntries.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAddAnotherButton(),
        ],

        // Botão de analisar
        if (_platformEntries.isNotEmpty && _platformEntries.any((e) => e.profileImages.isNotEmpty)) ...[
          const SizedBox(height: 32),
          _buildAnalyzeButton(),
        ],

        // Mensagem de erro
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlatformGrid({required Function(PlatformType) onSelect}) {
    final platforms = [
      _PlatformInfo(PlatformType.instagram, 'Instagram', 'assets/images/instagram.png', const Color(0xFFE1306C)),
      _PlatformInfo(PlatformType.tinder, 'Tinder', 'assets/images/tinder.png', const Color(0xFFFF6B6B)),
      _PlatformInfo(PlatformType.bumble, 'Bumble', 'assets/images/bumble.png', const Color(0xFFFFD93D)),
      _PlatformInfo(PlatformType.hinge, 'Hinge', 'assets/images/hinge.png', const Color(0xFF8B5CF6)),
      _PlatformInfo(PlatformType.happn, 'Happn', null, const Color(0xFFFF9500)),
      _PlatformInfo(PlatformType.umatch, 'Umatch', null, const Color(0xFF00C853)),
      _PlatformInfo(PlatformType.whatsapp, 'WhatsApp', null, const Color(0xFF25D366)),
      _PlatformInfo(PlatformType.outro, 'Outro', null, const Color(0xFF6B7280)),
    ];

    // Filtrar plataformas já adicionadas
    final availablePlatforms = platforms.where((p) =>
      !_platformEntries.any((e) => e.type == p.type)
    ).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: availablePlatforms.map((platform) {
        return _buildPlatformChip(platform, onSelect);
      }).toList(),
    );
  }

  Widget _buildPlatformChip(_PlatformInfo platform, Function(PlatformType) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(platform.type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (platform.assetPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  platform.assetPath!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: platform.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: platform.color,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              platform.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSection(int index, _PlatformEntry entry) {
    final platformInfo = _getPlatformInfo(entry.type);

    return Container(
      margin: EdgeInsets.only(top: index > 0 ? 20 : 0, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: platformInfo.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da plataforma
          Row(
            children: [
              if (platformInfo.assetPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    platformInfo.assetPath!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: platformInfo.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: platformInfo.color,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  platformInfo.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_platformEntries.length > 1)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                  onPressed: () => _removePlatform(index),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Instagram: mode selector + content
          if (entry.type == PlatformType.instagram) ...[
            if (entry.instagramUploadMode == InstagramUploadMode.none) ...[
              const Text(
                'Como você quer adicionar?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setInstagramMode(index, InstagramUploadMode.generalScreenshot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A4E)),
                        ),
                        child: Column(
                          children: [
                            const Text('📸', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            const Text(
                              'Print do Perfil',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Um print geral\ndo perfil dela',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setInstagramMode(index, InstagramUploadMode.individualPhotos),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A4E)),
                        ),
                        child: Column(
                          children: [
                            const Text('🖼', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            const Text(
                              'Fotos Individuais',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Adicione as fotos\numa por uma',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show mode label + change button
              Row(
                children: [
                  Text(
                    entry.instagramUploadMode == InstagramUploadMode.generalScreenshot
                        ? '📸 Print do Perfil'
                        : '🖼 Fotos Individuais',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _setInstagramMode(index, InstagramUploadMode.none),
                    child: Text(
                      'Trocar modo',
                      style: TextStyle(
                        color: const Color(0xFFE91E63),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (entry.instagramUploadMode == InstagramUploadMode.generalScreenshot) ...[
                // General screenshot mode
                if (entry.profileImages.isEmpty) ...[
                  GestureDetector(
                    onTap: () => _pickGeneralScreenshot(index),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3A3A4E)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.screenshot_outlined, color: Colors.grey.shade500, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'Adicionar print do perfil',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tire um print da página do perfil dela no Instagram',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Show screenshot + cropped profile pic
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full screenshot
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF3A3A4E)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  entry.profileImages.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    entry.profileImages.clear();
                                    entry.profileBase64s.clear();
                                    entry.profileMediaTypes.clear();
                                    entry.croppedProfilePicBytes = null;
                                    entry.croppedProfilePicBase64 = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Cropped profile pic
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Text(
                              'Foto de perfil\n(recorte automático)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            if (entry.croppedProfilePicBytes != null)
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE91E63).withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.memory(
                                    entry.croppedProfilePicBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Individual photos mode - Instagram-like layout
                _buildIndividualPhotosLayout(index, entry),
              ],
            ],
          ] else ...[
            // Non-Instagram platforms: original behavior
            const Text(
              'Fotos do Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione as fotos do perfil dela (pode adicionar várias)',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileImagesGrid(index, entry),
          ],

          // Stories (apenas Instagram - general screenshot mode; individual photos has stories inline)
          if (entry.type == PlatformType.instagram && entry.instagramUploadMode == InstagramUploadMode.generalScreenshot) ...[
            const SizedBox(height: 16),
            const Text(
              'Stories (opcional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione stories para usar como contexto nas sugestões',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...entry.storyImages.asMap().entries.map((storyEntry) {
                    return _buildStoryThumbnail(
                      index,
                      storyEntry.key,
                      storyEntry.value,
                    );
                  }),
                  _buildAddStoryButton(index),
                ],
              ),
            ),
          ],

          // Opening Move (apenas Bumble)
          if (entry.type == PlatformType.bumble) ...[
            const SizedBox(height: 16),
            _buildUploadArea(
              title: 'Opening Move (opcional)',
              subtitle: 'Print da pergunta que ela escolheu',
              imageBytes: entry.openingMoveImageBytes,
              onUpload: () => _pickImage(index, isOpeningMove: true),
              onRemove: () => _removeImage(index, isOpeningMove: true),
              isSmall: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndividualPhotosLayout(int platformIndex, _PlatformEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        TextField(
          controller: entry.nameController,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Nome dela',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade500, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        // Bio field
        TextField(
          controller: entry.bioController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'Bio / descricao do perfil',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Stories section (horizontal scroll, Instagram-style)
        Row(
          children: [
            const Text(
              'Stories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(opcional)',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...entry.storyImages.asMap().entries.map((storyEntry) {
                return _buildStoryThumbnail(platformIndex, storyEntry.key, storyEntry.value);
              }),
              _buildAddStoryButton(platformIndex),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Divider
        Container(
          height: 1,
          color: const Color(0xFF2A2A3E),
        ),
        const SizedBox(height: 16),
        // Photos section - grid layout
        Row(
          children: [
            const Text(
              'Fotos do Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'A 1a foto vira avatar',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildProfileImagesGrid(platformIndex, entry),
      ],
    );
  }

  Widget _buildUploadArea({
    required String title,
    required String subtitle,
    required Uint8List? imageBytes,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    bool isSmall = false,
  }) {
    if (imageBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: isSmall ? 150 : 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onUpload,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 24 : 32),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3A3A4E),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.grey.shade500,
              size: isSmall ? 28 : 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isSmall ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagesGrid(int platformIndex, _PlatformEntry entry) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Imagens já adicionadas
        ...entry.profileImages.asMap().entries.map((imgEntry) {
          return _buildProfileImageThumbnail(
            platformIndex,
            imgEntry.key,
            imgEntry.value,
          );
        }),
        // Botão de adicionar mais
        _buildAddProfileImageButton(platformIndex),
      ],
    );
  }

  Widget _buildProfileImageThumbnail(int platformIndex, int imageIndex, Uint8List imageBytes) {
    return Container(
      width: 100,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A4E)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Badge de número
          if (imageIndex == 0)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Botão de remover
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeProfileImage(platformIndex, imageIndex),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProfileImageButton(int platformIndex) {
    return GestureDetector(
      onTap: () => _pickProfileImage(platformIndex),
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3A3A4E),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.grey.shade500,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicionar',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '(várias)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryThumbnail(int platformIndex, int storyIndex, Uint8List imageBytes) {
    return Container(
      width: 80,
      height: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeStory(platformIndex, storyIndex),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton(int platformIndex) {
    return GestureDetector(
      onTap: () => _pickStory(platformIndex),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A4E)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Stories',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
            Text(
              '(várias)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnotherButton() {
    // Verificar se ainda há plataformas disponíveis
    final allPlatforms = PlatformType.values;
    final addedPlatforms = _platformEntries.map((e) => e.type).toSet();
    final hasAvailable = allPlatforms.any((p) => !addedPlatforms.contains(p));

    if (!hasAvailable) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showAddPlatformDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A2A3E),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Adicionar outra rede social',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _analyzeAndCreateProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Analisar e Criar Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addPlatform(PlatformType type) {
    setState(() {
      _platformEntries.add(_PlatformEntry(type: type));
      _errorMessage = null;
    });
  }

  void _removePlatform(int index) {
    setState(() {
      _platformEntries.removeAt(index);
    });
  }

  void _showAddPlatformDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
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
              const Text(
                'Adicionar Rede Social',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildPlatformGrid(onSelect: (type) {
                Navigator.pop(context);
                _addPlatform(type);
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Comprime a imagem para caber no limite do Firestore (~1MB)
  Future<Uint8List> _compressImage(Uint8List bytes, {int maxSize = 800, int quality = 50}) async {
    try {
      // Decodifica a imagem
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Redimensiona se necessário
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

      // Codifica como JPEG com qualidade reduzida
      final compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      // Se falhar, retorna a imagem original
      return bytes;
    }
  }

  Future<void> _pickProfileImage(int platformIndex) async {
    try {
      // Permite selecionar múltiplas imagens de uma vez
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) return;

      for (final image in images) {
        final originalBytes = await image.readAsBytes();
        // Comprime a imagem manualmente (pickMultiImage ignora maxWidth/maxHeight na web)
        final bytes = await _compressImage(originalBytes, maxSize: 800, quality: 50);
        final base64 = base64Encode(bytes);
        // Após compressão, sempre será JPEG
        const mediaType = 'image/jpeg';

        setState(() {
          _platformEntries[platformIndex].profileImages.add(bytes);
          _platformEntries[platformIndex].profileBase64s.add(base64);
          _platformEntries[platformIndex].profileMediaTypes.add(mediaType);
        });
      }

      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar imagens: $e';
      });
    }
  }

  void _removeProfileImage(int platformIndex, int imageIndex) {
    setState(() {
      _platformEntries[platformIndex].profileImages.removeAt(imageIndex);
      _platformEntries[platformIndex].profileBase64s.removeAt(imageIndex);
      _platformEntries[platformIndex].profileMediaTypes.removeAt(imageIndex);
    });
  }

  Future<void> _pickImage(int index, {bool isOpeningMove = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      final originalBytes = await image.readAsBytes();
      // Comprime a imagem manualmente
      final bytes = await _compressImage(originalBytes, maxSize: 800, quality: 50);
      final base64 = base64Encode(bytes);
      const mediaType = 'image/jpeg';

      setState(() {
        if (isOpeningMove) {
          _platformEntries[index].openingMoveImageBytes = bytes;
          _platformEntries[index].openingMoveImageBase64 = base64;
          _platformEntries[index].openingMoveMediaType = mediaType;
        }
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar imagem: $e';
      });
    }
  }

  void _removeImage(int index, {bool isOpeningMove = false}) {
    setState(() {
      if (isOpeningMove) {
        _platformEntries[index].openingMoveImageBytes = null;
        _platformEntries[index].openingMoveImageBase64 = null;
        _platformEntries[index].openingMoveMediaType = null;
      }
    });
  }

  Future<void> _pickStory(int platformIndex) async {
    try {
      // Permite selecionar múltiplos stories de uma vez
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) return;

      for (final image in images) {
        final originalBytes = await image.readAsBytes();
        // Comprime a imagem manualmente
        final bytes = await _compressImage(originalBytes, maxSize: 800, quality: 50);
        final base64 = base64Encode(bytes);
        const mediaType = 'image/jpeg';

        setState(() {
          _platformEntries[platformIndex].storyImages.add(bytes);
          _platformEntries[platformIndex].storyBase64s.add(base64);
          _platformEntries[platformIndex].storyMediaTypes.add(mediaType);
        });
      }

      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar stories: $e';
      });
    }
  }

  void _removeStory(int platformIndex, int storyIndex) {
    setState(() {
      _platformEntries[platformIndex].storyImages.removeAt(storyIndex);
      _platformEntries[platformIndex].storyBase64s.removeAt(storyIndex);
      _platformEntries[platformIndex].storyMediaTypes.removeAt(storyIndex);
    });
  }

  /// Crops a square avatar from the image.
  /// Priority: 1) AI facePosition, 2) ML Kit face detection, 3) center-top fallback
  Future<Uint8List> _cropAvatarFromImage(Uint8List bytes, {
    Map<String, dynamic>? facePosition,
    String? platform,
    bool isScreenshot = false,
  }) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      int cropX, cropY, cropSize;
      final maxDim = min(image.width, image.height);

      if (facePosition != null &&
          facePosition['centerX'] != null &&
          facePosition['centerY'] != null &&
          facePosition['size'] != null) {
        // Priority 1: AI-provided face coordinates (0-100 percentages)
        final cx = (image.width * (facePosition['centerX'] as num) / 100).round();
        final cy = (image.height * (facePosition['centerY'] as num) / 100).round();
        final faceSize = (image.width * (facePosition['size'] as num) / 100).round();
        final padding = faceSize < (image.width * 0.2) ? 2.5 : 1.5;
        cropSize = (faceSize * padding).round().clamp(1, maxDim);
        cropX = (cx - cropSize ~/ 2).clamp(0, image.width - cropSize);
        cropY = (cy - cropSize ~/ 2).clamp(0, image.height - cropSize);
      } else {
        // Priority 2: Native CIDetector face detection (iOS)
        final faceRect = await _detectFaceNative(bytes, image.width, image.height);

        if (faceRect != null) {
          final paddingFactor = 0.45;
          final padW = (faceRect.width * paddingFactor).round();
          final padH = (faceRect.height * paddingFactor).round();
          final faceW = faceRect.width.round() + padW * 2;
          final faceH = faceRect.height.round() + padH * 2;
          cropSize = max(faceW, faceH).clamp(1, maxDim);
          cropX = (faceRect.center.dx - cropSize / 2).round().clamp(0, image.width - cropSize);
          cropY = (faceRect.center.dy - cropSize / 2).round().clamp(0, image.height - cropSize);
        } else {
          // Priority 3: Heuristic fallback
          final isPortrait = image.height > image.width * 1.3;
          if (isPortrait && isScreenshot) {
            cropSize = (image.width * 0.5).round().clamp(1, maxDim);
            cropX = ((image.width - cropSize) / 2).round().clamp(0, image.width - cropSize);
            cropY = (image.height * 0.05).round().clamp(0, image.height - cropSize);
          } else {
            cropSize = (image.width * 0.5).round().clamp(1, maxDim);
            cropX = ((image.width - cropSize) / 2).round().clamp(0, image.width - cropSize);
            cropY = (image.height * 0.08).round().clamp(0, image.height - cropSize);
          }
        }
      }

      final cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropSize, height: cropSize);
      final resized = img.copyResize(cropped, width: 200, height: 200);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      return bytes;
    }
  }

  /// Uses native CIDetector (iOS) via MethodChannel to detect the largest face.
  /// Returns the bounding box of the face, or null if no face found.
  static const _nativeChannel = MethodChannel('com.desenrolaai/native');

  Future<Rect?> _detectFaceNative(Uint8List bytes, int imageWidth, int imageHeight) async {
    try {
      final result = await _nativeChannel.invokeMethod('detectFace', {
        'imageBytes': bytes,
        'width': imageWidth,
        'height': imageHeight,
      });

      if (result == null) return null;

      final map = Map<String, dynamic>.from(result);
      return Rect.fromLTWH(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
        (map['width'] as num).toDouble(),
        (map['height'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Native face detection error: $e');
      return null;
    }
  }

  Future<void> _pickGeneralScreenshot(int platformIndex) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final originalBytes = await image.readAsBytes();
      final bytes = await _compressImage(originalBytes, maxSize: 1200, quality: 60);
      final base64str = base64Encode(bytes);
      const mediaType = 'image/jpeg';

      setState(() {
        final entry = _platformEntries[platformIndex];
        entry.profileImages = [bytes];
        entry.profileBase64s = [base64str];
        entry.profileMediaTypes = [mediaType];
        _errorMessage = null;
      });

      // Crop avatar using ML Kit face detection
      final entry = _platformEntries[platformIndex];
      final croppedBytes = await _cropAvatarFromImage(
        bytes,
        platform: entry.type.name,
        isScreenshot: true,
      );
      final croppedBase64 = base64Encode(croppedBytes);

      if (mounted) {
        setState(() {
          _platformEntries[platformIndex].croppedProfilePicBytes = croppedBytes;
          _platformEntries[platformIndex].croppedProfilePicBase64 = croppedBase64;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar imagem: $e';
      });
    }
  }

  void _setInstagramMode(int platformIndex, InstagramUploadMode mode) {
    setState(() {
      final entry = _platformEntries[platformIndex];
      entry.instagramUploadMode = mode;
      // Clear images when switching mode
      entry.profileImages.clear();
      entry.profileBase64s.clear();
      entry.profileMediaTypes.clear();
      entry.croppedProfilePicBytes = null;
      entry.croppedProfilePicBase64 = null;
    });
  }

  _PlatformInfo _getPlatformInfo(PlatformType type) {
    switch (type) {
      case PlatformType.instagram:
        return _PlatformInfo(type, 'Instagram', 'assets/images/instagram.png', const Color(0xFFE1306C));
      case PlatformType.tinder:
        return _PlatformInfo(type, 'Tinder', 'assets/images/tinder.png', const Color(0xFFFF6B6B));
      case PlatformType.bumble:
        return _PlatformInfo(type, 'Bumble', 'assets/images/bumble.png', const Color(0xFFFFD93D));
      case PlatformType.hinge:
        return _PlatformInfo(type, 'Hinge', 'assets/images/hinge.png', const Color(0xFF8B5CF6));
      case PlatformType.happn:
        return _PlatformInfo(type, 'Happn', null, const Color(0xFFFF9500));
      case PlatformType.innerCircle:
        return _PlatformInfo(type, 'Inner Circle', null, const Color(0xFF1E88E5));
      case PlatformType.umatch:
        return _PlatformInfo(type, 'Umatch', null, const Color(0xFF00C853));
      case PlatformType.whatsapp:
        return _PlatformInfo(type, 'WhatsApp', null, const Color(0xFF25D366));
      case PlatformType.outro:
        return _PlatformInfo(type, 'Outro', null, const Color(0xFF6B7280));
    }
  }

  Future<void> _analyzeAndCreateProfile() async {
    if (_platformEntries.isEmpty) return;

    // Verificar se pelo menos uma plataforma tem imagem
    final hasImage = _platformEntries.any((e) => e.profileImages.isNotEmpty);
    if (!hasImage) {
      setState(() {
        _errorMessage = 'Adicione pelo menos uma imagem de perfil';
      });
      return;
    }

    final appState = context.read<AppState>();
    final userId = appState.userId;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Usuário não autenticado';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final agentService = AgentService(baseUrl: appState.backendUrl);

      String? profileName;
      String? faceDescription;
      String? faceImageBase64;
      PlatformData? firstPlatform;
      List<PlatformData> additionalPlatforms = [];

      for (int i = 0; i < _platformEntries.length; i++) {
        final entry = _platformEntries[i];

        if (entry.profileImages.isEmpty) continue;

        // Check if user manually entered name/bio (individual photos mode)
        final manualName = entry.nameController.text.trim();
        final manualBio = entry.bioController.text.trim();

        // Analisar todas as imagens do perfil e combinar resultados
        List<String> allPhotoDescriptions = [];
        List<String> allInterests = [];
        String? bio;
        String? username;
        String? age;
        String? location;
        String? occupation;

        for (int imgIndex = 0; imgIndex < entry.profileBase64s.length; imgIndex++) {
          final imageBase64 = entry.profileBase64s[imgIndex];
          final mediaType = entry.profileMediaTypes[imgIndex];

          // Analisar imagem do perfil
          final result = await agentService.analyzeProfileImage(
            imageBase64: imageBase64,
            platform: entry.type.name,
            imageMediaType: mediaType,
          );

          if (!result.success) {
            throw Exception(result.errorMessage ?? 'Erro ao analisar imagem');
          }

          // Usar o primeiro nome/face encontrado
          if (faceImageBase64 == null) {
            if (profileName == null) {
              profileName = result.name;
              faceDescription = result.faceDescription;
            }
            // Crop avatar: AI facePosition > platform heuristic > pre-crop
            final isScreenshot = entry.instagramUploadMode == InstagramUploadMode.generalScreenshot
                || entry.type != PlatformType.instagram;
            try {
              final croppedBytes = await _cropAvatarFromImage(
                entry.profileImages[imgIndex],
                facePosition: result.facePosition,
                platform: entry.type.name,
                isScreenshot: isScreenshot,
              );
              faceImageBase64 = base64Encode(croppedBytes);
            } catch (_) {
              faceImageBase64 = entry.croppedProfilePicBase64 ?? imageBase64;
            }
          }

          // Combinar informações de todas as imagens
          if (result.bio != null && bio == null) bio = result.bio;
          if (result.username != null && username == null) username = result.username;
          if (result.age != null && age == null) age = result.age;
          if (result.location != null && location == null) location = result.location;
          if (result.occupation != null && occupation == null) occupation = result.occupation;

          // Acumular descrições e interesses
          if (result.photoDescriptions != null) {
            allPhotoDescriptions.addAll(result.photoDescriptions!);
          }
          if (result.interests != null) {
            for (final interest in result.interests!) {
              if (!allInterests.contains(interest)) {
                allInterests.add(interest);
              }
            }
          }
        }

        // Manual name/bio override from individual photos mode
        if (manualName.isNotEmpty) profileName = manualName;
        if (manualBio.isNotEmpty) bio = manualBio;

        // Criar lista de stories para Instagram
        List<StoryData>? stories;
        if (entry.type == PlatformType.instagram && entry.storyBase64s.isNotEmpty) {
          stories = [];
          for (int j = 0; j < entry.storyBase64s.length; j++) {
            // Analisar cada story
            final storyResult = await agentService.analyzeProfileImage(
              imageBase64: entry.storyBase64s[j],
              platform: 'instagram',
              imageMediaType: entry.storyMediaTypes[j],
            );

            stories.add(StoryData(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$j',
              imageBase64: entry.storyBase64s[j],
              description: storyResult.bio ?? storyResult.additionalInfo,
              createdAt: DateTime.now(),
            ));
          }
        }

        // Criar dados da plataforma
        PlatformData platformData = PlatformData(
          type: entry.type,
          username: username,
          bio: bio,
          age: age,
          location: location,
          occupation: occupation,
          interests: allInterests.isNotEmpty ? allInterests : null,
          photoDescriptions: allPhotoDescriptions.isNotEmpty ? allPhotoDescriptions : null,
          openingMove: null,
          stories: stories,
          profileImageBase64: entry.profileBase64s.first,
          profileImagesBase64: entry.profileBase64s, // Todas as imagens
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Analisar Opening Move do Bumble se existir
        if (entry.type == PlatformType.bumble && entry.openingMoveImageBase64 != null) {
          final omResult = await agentService.analyzeProfileImage(
            imageBase64: entry.openingMoveImageBase64!,
            platform: 'bumble',
            imageMediaType: entry.openingMoveMediaType ?? 'image/jpeg',
          );
          platformData = platformData.copyWith(
            openingMove: omResult.bio ?? omResult.additionalInfo,
          );
        }

        if (firstPlatform == null) {
          firstPlatform = platformData;
        } else {
          additionalPlatforms.add(platformData);
        }
      }

      if (firstPlatform == null) {
        throw Exception('Nenhuma plataforma válida encontrada');
      }

      // Criar perfil
      final profile = await _profileService.createProfile(
        userId: userId,
        name: profileName ?? 'Sem nome',
        faceDescription: faceDescription,
        faceImageBase64: faceImageBase64,
        initialPlatform: firstPlatform,
      );

      // Adicionar plataformas adicionais
      for (final platform in additionalPlatforms) {
        await _profileService.addPlatform(profile.id, platform);
      }

      if (!mounted) return;

      // Navegar para o detalhe do perfil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileDetailScreen(profileId: profile.id),
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Erro ao criar perfil: $e';
      });
    }
  }
}

// Classes auxiliares
class _PlatformEntry {
  final PlatformType type;
  // Múltiplas imagens de perfil
  List<Uint8List> profileImages = [];
  List<String> profileBase64s = [];
  List<String> profileMediaTypes = []; // Tipos de mídia (image/jpeg, image/png, etc)
  // Opening Move (Bumble)
  Uint8List? openingMoveImageBytes;
  String? openingMoveImageBase64;
  String? openingMoveMediaType;
  // Stories (Instagram)
  List<Uint8List> storyImages = [];
  List<String> storyBase64s = [];
  List<String> storyMediaTypes = [];
  // Instagram upload mode
  InstagramUploadMode instagramUploadMode = InstagramUploadMode.none;
  Uint8List? croppedProfilePicBytes;
  String? croppedProfilePicBase64;
  // Manual name/bio for individual photos mode
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  _PlatformEntry({required this.type});

  // Getters para compatibilidade
  Uint8List? get profileImageBytes => profileImages.isNotEmpty ? profileImages.first : null;
  String? get profileImageBase64 => profileBase64s.isNotEmpty ? profileBase64s.first : null;

  // Detecta o tipo de mídia baseado nos bytes da imagem
  static String detectMediaType(Uint8List bytes) {
    if (bytes.length >= 8) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // GIF: 47 49 46 38
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
        return 'image/gif';
      }
      // WebP: 52 49 46 46 ... 57 45 42 50
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes.length >= 12 && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'image/webp';
      }
    }
    // Default to jpeg
    return 'image/jpeg';
  }
}

class _PlatformInfo {
  final PlatformType type;
  final String name;
  final String? assetPath;
  final Color color;

  _PlatformInfo(this.type, this.name, this.assetPath, this.color);
}
