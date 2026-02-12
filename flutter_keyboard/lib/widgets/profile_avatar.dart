import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Reusable professional avatar widget with gradient border and glow.
/// Used consistently across the app for profile photos.
class ProfileAvatar extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String name;
  final double size;
  final double borderWidth;
  final bool showShadow;
  final Widget? badge;

  const ProfileAvatar({
    super.key,
    this.imageBytes,
    this.imageUrl,
    required this.name,
    this.size = 56,
    this.borderWidth = 2.5,
    this.showShadow = true,
    this.badge,
  });

  /// Convenience constructor that decodes a base64 string into image bytes.
  factory ProfileAvatar.fromBase64({
    Key? key,
    String? base64Image,
    String? imageUrl,
    required String name,
    double size = 56,
    double borderWidth = 2.5,
    bool showShadow = true,
    Widget? badge,
  }) {
    Uint8List? bytes;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        bytes = base64Decode(base64Image);
      } catch (_) {}
    }
    return ProfileAvatar(
      key: key,
      imageBytes: bytes,
      imageUrl: imageUrl,
      name: name,
      size: size,
      borderWidth: borderWidth,
      showShadow: showShadow,
      badge: badge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ringGap = size > 44 ? 2.0 : 1.5;
    final innerSize = size - borderWidth * 2 - ringGap * 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF5722), AppColors.warning],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: size * 0.18,
                      offset: Offset(0, size * 0.04),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.all(borderWidth),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundDark,
            ),
            padding: EdgeInsets.all(ringGap),
            child: ClipOval(
              child: _buildImage(innerSize),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -1,
            bottom: -1,
            child: badge!,
          ),
      ],
    );
  }

  Widget _buildImage(double innerSize) {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: innerSize,
        height: innerSize,
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: innerSize,
        height: innerSize,
        errorBuilder: (_, __, ___) => _buildFallback(innerSize),
      );
    }

    return _buildFallback(innerSize);
  }

  Widget _buildFallback(double innerSize) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: innerSize,
      height: innerSize,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.elevatedDark, AppColors.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: innerSize * 0.42,
          ),
        ),
      ),
    );
  }
}
