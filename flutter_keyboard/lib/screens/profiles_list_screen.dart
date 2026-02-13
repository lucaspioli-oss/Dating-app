import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import '../config/app_theme.dart';
import '../config/app_page_transitions.dart';
import '../config/app_haptics.dart';
import '../models/profile_model.dart';
import '../providers/app_state.dart';
import '../services/profile_service.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/app_error_state.dart';
import 'create_profile_screen.dart';
import 'profile_detail_screen.dart';

class ProfilesListScreen extends StatefulWidget {
  const ProfilesListScreen({super.key});

  @override
  State<ProfilesListScreen> createState() => _ProfilesListScreenState();
}

class _ProfilesListScreenState extends State<ProfilesListScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userId = appState.userId;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.loginToSeeContacts,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.contactsTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildAddButton(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizations.of(context)!.contactsSubtitle,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchProfilesHint,
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.elevatedDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.elevatedDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Lista de contatos
            Expanded(
              child: StreamBuilder<List<Profile>>(
                stream: _profileService.getProfiles(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerProfileList();
                  }

                  if (snapshot.hasError) {
                    return AppErrorState(
                      message: AppLocalizations.of(context)!.loadContactsError,
                      onRetry: () => setState(() {}),
                    );
                  }

                  final profiles = snapshot.data ?? [];

                  if (profiles.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filtered = _searchQuery.isEmpty
                      ? profiles
                      : profiles.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.noContactFound,
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                      ),
                    );
                  }

                  return _buildProfilesGrid(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _navigateToCreateProfile(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.textPrimary, size: 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    const Color(0xFFFF5722).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.addFirstMatchTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.addFirstMatchDescription,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _navigateToCreateProfile(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF5722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1, color: AppColors.textPrimary),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.addContactButton,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesGrid(List<Profile> profiles) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProfileCard(profiles[index]),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(Profile profile) {
    final platforms = profile.platforms.values.toList();
    final hasPreview = profile.lastMessagePreview != null;
    final activityDate = profile.lastActivityAt ?? profile.updatedAt;

    return GestureDetector(
      onTap: () => _navigateToProfileDetail(profile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.elevatedDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ProfileAvatar.fromBase64(
              base64Image: profile.faceImageBase64,
              name: profile.name,
              size: 56,
              heroTag: 'profile_avatar_${profile.id}',
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name + timestamp row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatRelativeTime(activityDate),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Message preview or platform logos
                  if (hasPreview)
                    Text(
                      profile.lastMessagePreview!,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Row(
                      children: [
                        ...platforms.take(4).map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildPlatformLogo(p.type),
                          );
                        }),
                        if (platforms.length > 4)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.elevatedDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${platforms.length - 4}',
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }

  Widget _buildPlatformLogo(PlatformType type) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: _getPlatformColor(type).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getPlatformColor(type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _getPlatformImage(type),
      ),
    );
  }

  Widget _getPlatformImage(PlatformType type) {
    // Try to use asset images first, fallback to styled container with icon
    final assetPath = _getPlatformAssetPath(type);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlatformFallback(type);
        },
      );
    }
    return _buildPlatformFallback(type);
  }

  String? _getPlatformAssetPath(PlatformType type) {
    switch (type) {
      case PlatformType.instagram:
        return 'assets/images/instagram.png';
      case PlatformType.tinder:
        return 'assets/images/tinder.png';
      case PlatformType.bumble:
        return 'assets/images/bumble.png';
      case PlatformType.hinge:
        return 'assets/images/hinge.png';
      case PlatformType.umatch:
        return 'assets/images/umatch.png';
      case PlatformType.whatsapp:
        return 'assets/images/whatsapp.png';
      default:
        return null;
    }
  }

  Widget _buildPlatformFallback(PlatformType type) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getPlatformGradient(type),
      ),
      child: Center(
        child: Text(
          _getPlatformInitial(type),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getPlatformInitial(PlatformType type) {
    switch (type) {
      case PlatformType.instagram:
        return 'IG';
      case PlatformType.tinder:
        return 'T';
      case PlatformType.bumble:
        return 'B';
      case PlatformType.hinge:
        return 'H';
      case PlatformType.happn:
        return 'Ha';
      case PlatformType.innerCircle:
        return 'IC';
      case PlatformType.umatch:
        return 'U';
      case PlatformType.whatsapp:
        return 'W';
      default:
        return '?';
    }
  }

  LinearGradient _getPlatformGradient(PlatformType type) {
    switch (type) {
      case PlatformType.instagram:
        return const LinearGradient(
          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlatformType.tinder:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF4458)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlatformType.bumble:
        return const LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFFC300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlatformType.hinge:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlatformType.happn:
        return const LinearGradient(
          colors: [Color(0xFFFF9500), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlatformType.umatch:
        return const LinearGradient(
          colors: [Color(0xFFE8344E), Color(0xFFD42040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PlatformType.whatsapp:
        return const LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getPlatformColor(PlatformType type) {
    switch (type) {
      case PlatformType.instagram:
        return const Color(0xFFE1306C);
      case PlatformType.tinder:
        return const Color(0xFFFF6B6B);
      case PlatformType.bumble:
        return const Color(0xFFFFD93D);
      case PlatformType.hinge:
        return const Color(0xFF8B5CF6);
      case PlatformType.happn:
        return const Color(0xFFFF9500);
      case PlatformType.umatch:
        return const Color(0xFFE8344E);
      case PlatformType.whatsapp:
        return const Color(0xFF25D366);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _navigateToCreateProfile() {
    AppHaptics.mediumImpact();
    Navigator.push(
      context,
      ScaleFadeRoute(page: const CreateProfileScreen()),
    );
  }

  void _navigateToProfileDetail(Profile profile) {
    AppHaptics.lightImpact();
    Navigator.push(
      context,
      FadeSlideRoute(page: ProfileDetailScreen(profileId: profile.id)),
    );
  }
}
