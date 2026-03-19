import 'package:flutter/material.dart';
// Supabase uses ISO8601 strings instead of Firestore Timestamps

/// Tipos de plataforma suportados
enum PlatformType {
  instagram,
  bumble,
  tinder,
  hinge,
  happn,
  innerCircle,
  umatch,
  whatsapp,
  outro;

  String get displayName {
    switch (this) {
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.bumble:
        return 'Bumble';
      case PlatformType.tinder:
        return 'Tinder';
      case PlatformType.hinge:
        return 'Hinge';
      case PlatformType.happn:
        return 'Happn';
      case PlatformType.innerCircle:
        return 'Inner Circle';
      case PlatformType.umatch:
        return 'Umatch';
      case PlatformType.whatsapp:
        return 'WhatsApp';
      case PlatformType.outro:
        return 'Outro';
    }
  }

  String get icon {
    switch (this) {
      case PlatformType.instagram:
        return '📸';
      case PlatformType.bumble:
        return '🐝';
      case PlatformType.tinder:
        return '🔥';
      case PlatformType.hinge:
        return '💜';
      case PlatformType.happn:
        return '📍';
      case PlatformType.innerCircle:
        return '⭐';
      case PlatformType.umatch:
        return '❤️';
      case PlatformType.whatsapp:
        return '💬';
      case PlatformType.outro:
        return '💬';
    }
  }

  bool get isDatingApp {
    return this != PlatformType.instagram;
  }
}

/// Dados de uma plataforma específica
class PlatformData {
  final PlatformType type;
  final String? username; // Para Instagram
  final String? bio;
  final String? age;
  final String? location;
  final String? occupation;
  final List<String>? interests;
  final List<String>? photoDescriptions;
  final String? openingMove; // Para Bumble
  final List<String>? prompts; // Para Hinge
  final String? additionalInfo;
  final List<StoryData>? stories; // Para Instagram
  final String? profileImageBase64; // Imagem principal do perfil
  final List<String>? profileImagesBase64; // Todas as imagens do perfil
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlatformData({
    required this.type,
    this.username,
    this.bio,
    this.age,
    this.location,
    this.occupation,
    this.interests,
    this.photoDescriptions,
    this.openingMove,
    this.prompts,
    this.additionalInfo,
    this.stories,
    this.profileImageBase64,
    this.profileImagesBase64,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'username': username,
      'bio': bio,
      'age': age,
      'location': location,
      'occupation': occupation,
      'interests': interests,
      'photoDescriptions': photoDescriptions,
      'openingMove': openingMove,
      'prompts': prompts,
      'additionalInfo': additionalInfo,
      'stories': stories?.map((s) => s.toMap()).toList(),
      'profileImageBase64': profileImageBase64,
      'profileImagesBase64': profileImagesBase64,
      'createdAt': createdAt != null ? createdAt!.toIso8601String() : null,
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
    };
  }

  factory PlatformData.fromMap(Map<String, dynamic> map) {
    return PlatformData(
      type: PlatformType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PlatformType.outro,
      ),
      username: map['username'],
      bio: map['bio'],
      age: map['age']?.toString(),
      location: map['location'],
      occupation: map['occupation'],
      interests: map['interests'] != null
          ? List<String>.from(map['interests'])
          : null,
      photoDescriptions: map['photoDescriptions'] != null
          ? List<String>.from(map['photoDescriptions'])
          : null,
      openingMove: map['openingMove'],
      prompts: map['prompts'] != null
          ? List<String>.from(map['prompts'])
          : null,
      additionalInfo: map['additionalInfo'],
      stories: map['stories'] != null
          ? (map['stories'] as List)
              .map((s) => StoryData.fromMap(s))
              .toList()
          : null,
      profileImageBase64: map['profileImageBase64'],
      profileImagesBase64: map['profileImagesBase64'] != null
          ? List<String>.from(map['profileImagesBase64'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  PlatformData copyWith({
    PlatformType? type,
    String? username,
    String? bio,
    String? age,
    String? location,
    String? occupation,
    List<String>? interests,
    List<String>? photoDescriptions,
    String? openingMove,
    List<String>? prompts,
    String? additionalInfo,
    List<StoryData>? stories,
    String? profileImageBase64,
    List<String>? profileImagesBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlatformData(
      type: type ?? this.type,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      location: location ?? this.location,
      occupation: occupation ?? this.occupation,
      interests: interests ?? this.interests,
      photoDescriptions: photoDescriptions ?? this.photoDescriptions,
      openingMove: openingMove ?? this.openingMove,
      prompts: prompts ?? this.prompts,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      stories: stories ?? this.stories,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      profileImagesBase64: profileImagesBase64 ?? this.profileImagesBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Dados de um story do Instagram
class StoryData {
  final String id;
  final String? imageBase64;
  final String? description;
  final DateTime createdAt;

  StoryData({
    required this.id,
    this.imageBase64,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageBase64': imageBase64,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StoryData.fromMap(Map<String, dynamic> map) {
    return StoryData(
      id: map['id'] ?? '',
      imageBase64: map['imageBase64'],
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Modelo principal de Perfil
class Profile {
  final String id;
  final String userId;
  final String name;
  final String? faceDescription;
  final String? faceImageBase64;
  final Map<PlatformType, PlatformData> platforms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;
  final String? lastMessagePreview;

  Profile({
    required this.id,
    required this.userId,
    required this.name,
    this.faceDescription,
    this.faceImageBase64,
    required this.platforms,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
    this.lastMessagePreview,
  });

  /// Retorna o Instagram se existir
  PlatformData? get instagram => platforms[PlatformType.instagram];

  /// Retorna lista de apps de relacionamento
  List<PlatformData> get datingApps =>
      platforms.values.where((p) => p.type.isDatingApp).toList();

  /// Verifica se tem Instagram
  bool get hasInstagram => platforms.containsKey(PlatformType.instagram);

  /// Verifica se tem algum app de relacionamento
  bool get hasDatingApps => datingApps.isNotEmpty;

  /// Retorna stories do Instagram
  List<StoryData> get stories => instagram?.stories ?? [];

  /// Indicador de temperatura baseado na última atividade
  String get temperatureIndicator {
    if (lastActivityAt == null) return '\u{1F480}'; // skull
    final diff = DateTime.now().difference(lastActivityAt!);
    if (diff.inDays > 7) return '\u{1F480}';
    if (diff.inDays >= 3) return '\u{2744}\u{FE0F}';
    if (diff.inHours >= 24) return '\u{1F525}';
    return '\u{1F525}\u{1F525}\u{1F525}';
  }

  /// Cor da temperatura baseada na última atividade
  Color get temperatureColor {
    if (lastActivityAt == null) return const Color(0xFF9E9E9E);
    final diff = DateTime.now().difference(lastActivityAt!);
    if (diff.inDays > 7) return const Color(0xFF9E9E9E);
    if (diff.inDays >= 3) return const Color(0xFF42A5F5);
    if (diff.inHours >= 24) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  /// Returns platforms as a raw string-keyed map (for Supabase JSON updates)
  Map<String, dynamic> get platformsMap {
    final m = <String, dynamic>{};
    platforms.forEach((key, value) {
      m[key.name] = value.toMap();
    });
    return m;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'faceDescription': faceDescription,
      'faceImageBase64': faceImageBase64,
      'platforms': platformsMap,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (lastActivityAt != null) 'lastActivityAt': lastActivityAt!.toIso8601String(),
      if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'user_id': userId,
      'name': name,
      'face_image_base64': faceImageBase64,
      'platforms': platformsMap,
      'updated_at': updatedAt.toIso8601String(),
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt!.toIso8601String(),
      if (lastMessagePreview != null) 'last_message_preview': lastMessagePreview,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final platformsMap = <PlatformType, PlatformData>{};

    if (map['platforms'] != null) {
      (map['platforms'] as Map<String, dynamic>).forEach((key, value) {
        final platformType = PlatformType.values.firstWhere(
          (e) => e.name == key,
          orElse: () => PlatformType.outro,
        );
        platformsMap[platformType] = PlatformData.fromMap(value);
      });
    }

    return Profile(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      faceDescription: map['faceDescription'],
      faceImageBase64: map['faceImageBase64'],
      platforms: platformsMap,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      lastActivityAt: map['lastActivityAt'] != null
          ? DateTime.parse(map['lastActivityAt'])
          : null,
      lastMessagePreview: map['lastMessagePreview'],
    );
  }

  factory Profile.fromSupabase(Map<String, dynamic> row) {
    return Profile.fromMap({
      ...row,
      'id': row['id'],
      'userId': row['user_id'] ?? row['userId'],
      'faceImageBase64': row['face_image_base64'] ?? row['faceImageBase64'],
      'faceDescription': row['face_description'] ?? row['faceDescription'],
      'createdAt': row['created_at'] ?? row['createdAt'],
      'updatedAt': row['updated_at'] ?? row['updatedAt'],
      'lastActivityAt': row['last_activity_at'] ?? row['lastActivityAt'],
      'lastMessagePreview': row['last_message_preview'] ?? row['lastMessagePreview'],
    });
  }

  Profile copyWith({
    String? id,
    String? userId,
    String? name,
    String? faceDescription,
    String? faceImageBase64,
    Map<PlatformType, PlatformData>? platforms,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
    String? lastMessagePreview,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      faceDescription: faceDescription ?? this.faceDescription,
      faceImageBase64: faceImageBase64 ?? this.faceImageBase64,
      platforms: platforms ?? this.platforms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
