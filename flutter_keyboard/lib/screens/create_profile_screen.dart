import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../config/app_theme.dart';
import '../config/app_page_transitions.dart';
import '../config/app_haptics.dart';
import '../models/profile_model.dart';
import '../providers/app_state.dart';
import '../services/agent_service.dart';
import '../services/profile_service.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.newProfileTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
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
    final l10n = AppLocalizations.of(this.context)!;
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
                  AppColors.primary.withOpacity(0.2),
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
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.analyzingProfileTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.extractingInfoMessage,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(this.context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Se não tem nenhuma plataforma, mostrar seletor
        if (_platformEntries.isEmpty) ...[
          Text(
            l10n.selectPlatformTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.platformQuestion,
            style: const TextStyle(
              color: AppColors.textTertiary,
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
        if (_platformEntries.isNotEmpty && (_platformEntries.any((e) => e.profileImages.isNotEmpty) || _platformEntries.any((e) => e.type == PlatformType.whatsapp && e.nameController.text.trim().isNotEmpty))) ...[
          const SizedBox(height: 32),
          _buildAnalyzeButton(),
        ],

        // Mensagem de erro
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
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
    final l10n = AppLocalizations.of(this.context)!;
    final platforms = [
      _PlatformInfo(PlatformType.instagram, 'Instagram', 'assets/images/instagram.png', const Color(0xFFE1306C)),
      _PlatformInfo(PlatformType.tinder, 'Tinder', 'assets/images/tinder.png', AppColors.primaryCoral),
      _PlatformInfo(PlatformType.bumble, 'Bumble', 'assets/images/bumble.png', const Color(0xFFFFD93D)),
      _PlatformInfo(PlatformType.hinge, 'Hinge', 'assets/images/hinge.png', const Color(0xFF8B5CF6)),
      _PlatformInfo(PlatformType.happn, 'Happn', null, const Color(0xFFFF9500)),
      _PlatformInfo(PlatformType.umatch, 'Umatch', null, const Color(0xFF00C853)),
      _PlatformInfo(PlatformType.whatsapp, 'WhatsApp', 'assets/images/whatsapp.png', const Color(0xFF25D366)),
      _PlatformInfo(PlatformType.outro, l10n.otherLabel, null, const Color(0xFF6B7280)),
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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.elevatedDark),
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
                color: AppColors.textPrimary,
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
    final l10n = AppLocalizations.of(this.context)!;
    final platformInfo = _getPlatformInfo(entry.type);

    return Container(
      margin: EdgeInsets.only(top: index > 0 ? 20 : 0, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
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
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_platformEntries.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                  onPressed: () => _removePlatform(index),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Instagram: mode selector + content
          if (entry.type == PlatformType.instagram) ...[
            if (entry.instagramUploadMode == InstagramUploadMode.none) ...[
              Text(
                l10n.howToAddQuestion,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
                          color: AppColors.elevatedDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A4E)),
                        ),
                        child: Column(
                          children: [
                            const Text('\uD83D\uDCF8', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.profileScreenshotMode,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.profileScreenshotDesc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
                          color: AppColors.elevatedDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A4E)),
                        ),
                        child: Column(
                          children: [
                            const Text('\uD83D\uDDBC', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.profilePhotosMode,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.profilePhotosDesc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
                        ? '\u{1F4F8} ${l10n.profileScreenshotMode}'
                        : '\u{1F5BC} ${l10n.profilePhotosMode}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _setInstagramMode(index, InstagramUploadMode.none),
                    child: Text(
                      l10n.changeMode,
                      style: TextStyle(
                        color: AppColors.primary,
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
                        color: AppColors.elevatedDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3A3A4E)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.screenshot_outlined, color: AppColors.textTertiary, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            l10n.addProfileScreenshot,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.screenshotInstructions,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                                  child: const Icon(Icons.close, size: 14, color: AppColors.textPrimary),
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
                              l10n.croppedProfilePicLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            if (entry.croppedProfilePicBytes != null)
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
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
          ] else if (entry.type == PlatformType.whatsapp) ...[
            // WhatsApp: contact picker + optional photos
            GestureDetector(
              onTap: () => _pickWhatsAppContact(index),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.elevatedDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.contacts, color: const Color(0xFF25D366), size: 32),
                    const SizedBox(height: 8),
                    Text(l10n.importFromContacts,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(l10n.contactAutoFill,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Manual name field (pre-filled from contact)
            TextFormField(
              controller: entry.nameController,
              decoration: InputDecoration(
                labelText: l10n.nameLabel,
                hintText: l10n.contactNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: AppColors.elevatedDark,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            if (entry.contactPhoneNumber != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.elevatedDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: AppColors.textTertiary, size: 18),
                    const SizedBox(width: 8),
                    Text(entry.contactPhoneNumber!,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              controller: entry.bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.bioContextLabel,
                hintText: l10n.bioContextHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.elevatedDark,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.profilePhotosOptionalLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildProfileImagesGrid(index, entry),
          ] else ...[
            // Non-Instagram platforms: original behavior
            Text(
              l10n.profilePhotosTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profilePhotosDescription,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileImagesGrid(index, entry),
          ],

          // Stories (apenas Instagram - general screenshot mode; individual photos has stories inline)
          if (entry.type == PlatformType.instagram && entry.instagramUploadMode == InstagramUploadMode.generalScreenshot) ...[
            const SizedBox(height: 16),
            Text(
              l10n.storiesOptionalTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.storiesDescription,
              style: const TextStyle(
                color: AppColors.textTertiary,
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
              title: l10n.openingMoveTitle,
              subtitle: l10n.openingMoveSubtitle,
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
    final l10n = AppLocalizations.of(this.context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        TextField(
          controller: entry.nameController,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: l10n.nameInputHint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: AppColors.elevatedDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textTertiary, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        // Bio field
        TextField(
          controller: entry.bioController,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: l10n.bioInputHint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            filled: true,
            fillColor: AppColors.elevatedDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Icon(Icons.info_outline, color: AppColors.textTertiary, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Stories section (horizontal scroll, Instagram-style)
        Row(
          children: [
            Text(
              l10n.storiesLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.optionalLabel,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
          color: AppColors.elevatedDark,
        ),
        const SizedBox(height: 16),
        // Photos section - grid layout
        Row(
          children: [
            Text(
              l10n.profilePhotosTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              l10n.firstPhotoAvatarInfo,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
              color: AppColors.textPrimary,
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
                  color: AppColors.elevatedDark,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppColors.textPrimary),
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
          color: AppColors.elevatedDark,
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
              color: AppColors.textTertiary,
              size: isSmall ? 28 : 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isSmall ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(this.context)!.mainPhotoLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
                child: const Icon(Icons.close, size: 14, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProfileImageButton(int platformIndex) {
    final l10n = AppLocalizations.of(this.context)!;
    return GestureDetector(
      onTap: () => _pickProfileImage(platformIndex),
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.elevatedDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3A3A4E),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addButton,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.multipleLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
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
                color: AppColors.surfaceDark,
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
                child: const Icon(Icons.close, size: 12, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton(int platformIndex) {
    final l10n = AppLocalizations.of(this.context)!;
    return GestureDetector(
      onTap: () => _pickStory(platformIndex),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.elevatedDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A4E)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add,
              color: AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.storiesLabel,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
            Text(
              l10n.multipleLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnotherButton() {
    final l10n = AppLocalizations.of(this.context)!;
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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.elevatedDark,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.addAnotherPlatform,
              style: const TextStyle(
                color: AppColors.textTertiary,
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
            colors: [AppColors.primary, Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(this.context)!.analyzeAndCreateButton,
              style: const TextStyle(
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

  Future<void> _pickWhatsAppContact(int platformIndex) async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      final l10n = AppLocalizations.of(this.context)!;
      setState(() {
        _errorMessage = l10n.contactPermissionError;
      });
      return;
    }

    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;

    final fullContact = await FlutterContacts.getContact(contact.id,
      withProperties: true,
      withPhoto: true,
      withThumbnail: true,
    );
    if (fullContact == null) return;

    setState(() {
      final entry = _platformEntries[platformIndex];
      entry.nameController.text = fullContact.displayName;

      if (fullContact.phones.isNotEmpty) {
        entry.contactPhoneNumber = fullContact.phones.first.number;
      }

      // Try full photo first, fallback to thumbnail
      final photoBytes = fullContact.photo ?? fullContact.thumbnail;
      if (photoBytes != null && photoBytes.isNotEmpty) {
        final bytes = Uint8List.fromList(photoBytes);
        final base64str = base64Encode(bytes);
        entry.profileImages = [bytes];
        entry.profileBase64s = [base64str];
        entry.profileMediaTypes = [_PlatformEntry.detectMediaType(bytes)];
      }

      _errorMessage = null;
    });
  }

  void _removePlatform(int index) {
    setState(() {
      _platformEntries.removeAt(index);
    });
  }

  void _showAddPlatformDialog() {
    final l10n = AppLocalizations.of(this.context)!;
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
              Text(
                l10n.addSocialNetworkTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
      final l10n = AppLocalizations.of(this.context)!;
      setState(() {
        _errorMessage = '${l10n.loadImagesError} $e';
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
      final l10n = AppLocalizations.of(this.context)!;
      setState(() {
        _errorMessage = '${l10n.loadImageError} $e';
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
      final l10n = AppLocalizations.of(this.context)!;
      setState(() {
        _errorMessage = '${l10n.loadStoriesError} $e';
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
        final isPortrait = image.height > image.width * 1.3;
        final isInstagramScreenshot = platform == 'instagram' && isScreenshot && isPortrait;

        // Priority 2: Native CIDetector face detection (iOS)
        final faceRect = await _detectFaceNative(bytes, image.width, image.height);

        if (faceRect != null) {
          if (isInstagramScreenshot) {
            // Instagram: only accept face if it's in the profile circle region
            // (top-left: X < 35% of width, Y < 25% of height)
            final inProfileRegion =
                faceRect.center.dx < image.width * 0.35 &&
                faceRect.center.dy < image.height * 0.25;

            if (inProfileRegion) {
              // Face found in avatar area — crop centered on it
              final paddingFactor = 0.6;
              final padW = (faceRect.width * paddingFactor).round();
              final padH = (faceRect.height * paddingFactor).round();
              final faceW = faceRect.width.round() + padW * 2;
              final faceH = faceRect.height.round() + padH * 2;
              cropSize = max(faceW, faceH).clamp(1, maxDim);
              cropX = (faceRect.center.dx - cropSize / 2).round().clamp(0, image.width - cropSize);
              cropY = (faceRect.center.dy - cropSize / 2).round().clamp(0, image.height - cropSize);
            } else {
              // Face is from grid photos — use heuristic for avatar position
              cropSize = (image.width * 0.20).round().clamp(1, maxDim);
              cropX = (image.width * 0.03).round().clamp(0, image.width - cropSize);
              cropY = (image.height * 0.08).round().clamp(0, image.height - cropSize);
            }
          } else {
            final paddingFactor = 0.45;
            final padW = (faceRect.width * paddingFactor).round();
            final padH = (faceRect.height * paddingFactor).round();
            final faceW = faceRect.width.round() + padW * 2;
            final faceH = faceRect.height.round() + padH * 2;
            cropSize = max(faceW, faceH).clamp(1, maxDim);
            cropX = (faceRect.center.dx - cropSize / 2).round().clamp(0, image.width - cropSize);
            cropY = (faceRect.center.dy - cropSize / 2).round().clamp(0, image.height - cropSize);
          }
        } else if (isInstagramScreenshot) {
          // No face detected — use heuristic for Instagram avatar position
          cropSize = (image.width * 0.20).round().clamp(1, maxDim);
          cropX = (image.width * 0.03).round().clamp(0, image.width - cropSize);
          cropY = (image.height * 0.08).round().clamp(0, image.height - cropSize);
        } else if (isPortrait && isScreenshot) {
            // Other dating app screenshots: face usually center-top
            cropSize = (image.width * 0.5).round().clamp(1, maxDim);
            cropX = ((image.width - cropSize) / 2).round().clamp(0, image.width - cropSize);
            cropY = (image.height * 0.05).round().clamp(0, image.height - cropSize);
          } else {
            // Non-screenshot or landscape
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
      final l10n = AppLocalizations.of(this.context)!;
      setState(() {
        _errorMessage = '${l10n.loadImageError} $e';
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
        return _PlatformInfo(type, 'Tinder', 'assets/images/tinder.png', AppColors.primaryCoral);
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
        return _PlatformInfo(type, AppLocalizations.of(this.context)!.otherLabel, null, const Color(0xFF6B7280));
    }
  }

  Future<void> _analyzeAndCreateProfile() async {
    if (_platformEntries.isEmpty) return;

    // Verificar se pelo menos uma plataforma tem imagem
    final hasImage = _platformEntries.any((e) => e.profileImages.isNotEmpty);
    final hasWhatsAppContact = _platformEntries.any((e) =>
      e.type == PlatformType.whatsapp && e.nameController.text.trim().isNotEmpty);
    final l10n = AppLocalizations.of(this.context)!;
    if (!hasImage && !hasWhatsAppContact) {
      setState(() {
        _errorMessage = l10n.addImageOrContactError;
      });
      return;
    }

    final appState = context.read<AppState>();
    final userId = appState.userId;

    if (userId == null) {
      setState(() {
        _errorMessage = l10n.userNotAuthenticated;
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

        if (entry.profileImages.isEmpty) {
          // WhatsApp contact without photos: create platform data from name/bio
          if (entry.type == PlatformType.whatsapp && entry.nameController.text.trim().isNotEmpty) {
            final manualName = entry.nameController.text.trim();
            profileName ??= manualName;

            final platformData = PlatformData(
              type: PlatformType.whatsapp,
              bio: entry.bioController.text.trim().isNotEmpty ? entry.bioController.text.trim() : null,
              additionalInfo: entry.contactPhoneNumber != null ? '${l10n.phonePrefix} ${entry.contactPhoneNumber}' : null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            if (firstPlatform == null) {
              firstPlatform = platformData;
            } else {
              additionalPlatforms.add(platformData);
            }
          }
          continue;
        }

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
            throw Exception(result.errorMessage ?? l10n.imageAnalysisError);
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
        throw Exception(l10n.noValidPlatform);
      }

      // Criar perfil
      final profile = await _profileService.createProfile(
        userId: userId,
        name: profileName ?? l10n.noNameFallback,
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
      AppHaptics.mediumImpact();
      Navigator.pushReplacement(
        context,
        FadeSlideRoute(page: ProfileDetailScreen(profileId: profile.id)),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = '${l10n.createProfileError} $e';
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
  String? contactPhoneNumber;

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
