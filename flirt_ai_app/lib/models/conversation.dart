// Helper para parsing de data robusto
DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    // Tenta ISO 8601
    try {
      return DateTime.parse(value);
    } catch (_) {}
    // Tenta timestamp como string
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    } catch (_) {}
  }
  return DateTime.now();
}

class Message {
  final String id;
  final String role; // 'user' ou 'match'
  final String content;
  final DateTime timestamp;
  final bool? wasAiSuggestion;
  final String? tone;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.wasAiSuggestion,
    this.tone,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: _parseDate(json['timestamp']),
      wasAiSuggestion: json['wasAiSuggestion'],
      tone: json['tone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (wasAiSuggestion != null) 'wasAiSuggestion': wasAiSuggestion,
      if (tone != null) 'tone': tone,
    };
  }
}

class DetectedPatterns {
  final String responseLength; // 'short', 'medium', 'long'
  final String emotionalTone; // 'warm', 'neutral', 'cold'
  final bool useEmojis;
  final String flirtLevel; // 'low', 'medium', 'high'
  final DateTime lastUpdated;

  DetectedPatterns({
    required this.responseLength,
    required this.emotionalTone,
    required this.useEmojis,
    required this.flirtLevel,
    required this.lastUpdated,
  });

  factory DetectedPatterns.fromJson(Map<String, dynamic> json) {
    return DetectedPatterns(
      responseLength: json['responseLength'] ?? 'medium',
      emotionalTone: json['emotionalTone'] ?? 'neutral',
      useEmojis: json['useEmojis'] ?? false,
      flirtLevel: json['flirtLevel'] ?? 'medium',
      lastUpdated: _parseDate(json['lastUpdated']),
    );
  }

  String get responseLengthEmoji {
    switch (responseLength) {
      case 'short':
        return '📏';
      case 'long':
        return '📜';
      default:
        return '📄';
    }
  }

  String get emotionalToneEmoji {
    switch (emotionalTone) {
      case 'warm':
        return '🔥';
      case 'cold':
        return '❄️';
      default:
        return '😐';
    }
  }

  String get flirtLevelEmoji {
    switch (flirtLevel) {
      case 'high':
        return '🔥';
      case 'low':
        return '❄️';
      default:
        return '😊';
    }
  }
}

class LearnedInfo {
  final List<String>? hobbies;
  final List<String>? lifestyle;
  final List<String>? dislikes;
  final List<String>? goals;
  final List<String>? personality;

  LearnedInfo({
    this.hobbies,
    this.lifestyle,
    this.dislikes,
    this.goals,
    this.personality,
  });

  factory LearnedInfo.fromJson(Map<String, dynamic> json) {
    return LearnedInfo(
      hobbies: json['hobbies'] != null ? List<String>.from(json['hobbies']) : null,
      lifestyle: json['lifestyle'] != null ? List<String>.from(json['lifestyle']) : null,
      dislikes: json['dislikes'] != null ? List<String>.from(json['dislikes']) : null,
      goals: json['goals'] != null ? List<String>.from(json['goals']) : null,
      personality: json['personality'] != null ? List<String>.from(json['personality']) : null,
    );
  }
}

class Analytics {
  final int totalMessages;
  final int aiSuggestionsUsed;
  final int customMessagesUsed;
  final String conversationQuality; // 'excellent', 'good', 'average', 'poor'

  Analytics({
    required this.totalMessages,
    required this.aiSuggestionsUsed,
    required this.customMessagesUsed,
    required this.conversationQuality,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      totalMessages: json['totalMessages'],
      aiSuggestionsUsed: json['aiSuggestionsUsed'],
      customMessagesUsed: json['customMessagesUsed'],
      conversationQuality: json['conversationQuality'],
    );
  }

  String get qualityEmoji {
    switch (conversationQuality) {
      case 'excellent':
        return '⭐⭐⭐';
      case 'good':
        return '⭐⭐';
      case 'average':
        return '⭐';
      default:
        return '⚠️';
    }
  }
}

class ConversationAvatar {
  final String matchName;
  final String? username;         // Para Instagram: @usuario (sem @)
  final String platform;
  final String? bio;
  final List<String>? photoDescriptions;
  final String? age;
  final String? location;
  final List<String>? interests;
  final String? faceImageUrl;     // URL da imagem do rosto
  final DetectedPatterns detectedPatterns;
  final LearnedInfo learnedInfo;
  final Analytics analytics;

  ConversationAvatar({
    required this.matchName,
    this.username,
    required this.platform,
    this.bio,
    this.photoDescriptions,
    this.age,
    this.location,
    this.interests,
    this.faceImageUrl,
    required this.detectedPatterns,
    required this.learnedInfo,
    required this.analytics,
  });

  factory ConversationAvatar.fromJson(Map<String, dynamic> json) {
    return ConversationAvatar(
      matchName: json['matchName'] ?? '',
      username: json['username'],
      platform: json['platform'] ?? 'tinder',
      bio: json['bio'],
      photoDescriptions: json['photoDescriptions'] != null
          ? List<String>.from(json['photoDescriptions'])
          : null,
      age: json['age'],
      location: json['location'],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      faceImageUrl: json['faceImageUrl'],
      detectedPatterns: json['detectedPatterns'] != null
          ? DetectedPatterns.fromJson(json['detectedPatterns'])
          : DetectedPatterns(
              responseLength: 'medium',
              emotionalTone: 'neutral',
              useEmojis: false,
              flirtLevel: 'medium',
              lastUpdated: DateTime.now(),
            ),
      learnedInfo: json['learnedInfo'] != null
          ? LearnedInfo.fromJson(json['learnedInfo'])
          : LearnedInfo(),
      analytics: json['analytics'] != null
          ? Analytics.fromJson(json['analytics'])
          : Analytics(
              totalMessages: 0,
              aiSuggestionsUsed: 0,
              customMessagesUsed: 0,
              conversationQuality: 'average',
            ),
    );
  }
}

class Conversation {
  final String id;
  final ConversationAvatar avatar;
  final List<Message> messages;
  final String currentTone;
  final String status;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.avatar,
    required this.messages,
    required this.currentTone,
    required this.status,
    required this.createdAt,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      avatar: ConversationAvatar.fromJson(json['avatar'] ?? {}),
      messages: json['messages'] != null
          ? (json['messages'] as List).map((m) => Message.fromJson(m)).toList()
          : [],
      currentTone: json['currentTone'] ?? 'expert',
      status: json['status'] ?? 'active',
      createdAt: _parseDate(json['createdAt']),
      lastMessageAt: _parseDate(json['lastMessageAt']),
    );
  }
}

class ConversationListItem {
  final String id;
  final String matchName;
  final String? username;         // Para Instagram
  final String platform;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String? faceImageUrl;     // URL da imagem do rosto
  final String? age;
  final Map<String, String> avatar;

  ConversationListItem({
    required this.id,
    required this.matchName,
    this.username,
    required this.platform,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.faceImageUrl,
    this.age,
    required this.avatar,
  });

  factory ConversationListItem.fromJson(Map<String, dynamic> json) {
    return ConversationListItem(
      id: json['id'] ?? '',
      matchName: json['matchName'] ?? '',
      username: json['username'],
      platform: json['platform'] ?? 'tinder',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: _parseDate(json['lastMessageAt']),
      unreadCount: json['unreadCount'] ?? 0,
      faceImageUrl: json['faceImageUrl'],
      age: json['age'],
      avatar: json['avatar'] != null ? Map<String, String>.from(json['avatar']) : {},
    );
  }

  String get platformEmoji {
    switch (platform) {
      case 'tinder':
        return '🔥';
      case 'bumble':
        return '💛';
      case 'hinge':
        return '💕';
      case 'instagram':
        return '📸';
      default:
        return '📱';
    }
  }

  /// Retorna o nome a exibir (username para Instagram, nome para outros)
  String get displayName {
    if (platform == 'instagram' && username != null && username!.isNotEmpty) {
      return '@$username';
    }
    return matchName;
  }

  /// Retorna o nome com idade se disponível
  String get displayNameWithAge {
    final name = displayName;
    if (age != null && age!.isNotEmpty) {
      return '$name, $age';
    }
    return name;
  }
}
