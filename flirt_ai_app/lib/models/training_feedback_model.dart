/// Modelo para feedback de treinamento
class TrainingFeedback {
  final String id;
  final String category;
  final String? subcategory;
  final String instruction;
  final List<String> examples;
  final List<String> tags;
  final String priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int usageCount;

  TrainingFeedback({
    required this.id,
    required this.category,
    this.subcategory,
    required this.instruction,
    this.examples = const [],
    this.tags = const [],
    this.priority = 'medium',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.usageCount = 0,
  });

  factory TrainingFeedback.fromJson(Map<String, dynamic> json) {
    return TrainingFeedback(
      id: json['id'] ?? '',
      category: json['category'] ?? 'general',
      subcategory: json['subcategory'],
      instruction: json['instruction'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      priority: json['priority'] ?? 'medium',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      usageCount: json['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'instruction': instruction,
      'examples': examples,
      'tags': tags,
      'priority': priority,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  static const List<String> categories = [
    'opener',
    'reply',
    'calibration',
    'general',
    'what_works',
    'what_doesnt_work',
  ];

  static String categoryLabel(String category) {
    switch (category) {
      case 'opener':
        return '🎯 Abridores';
      case 'reply':
        return '💬 Respostas';
      case 'calibration':
        return '🔥 Calibragem';
      case 'general':
        return '📋 Geral';
      case 'what_works':
        return '✅ O que Funciona';
      case 'what_doesnt_work':
        return '❌ O que Não Funciona';
      default:
        return category;
    }
  }

  static const List<String> priorities = ['high', 'medium', 'low'];

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '🔴 Alta';
      case 'medium':
        return '🟡 Média';
      case 'low':
        return '🟢 Baixa';
      default:
        return priority;
    }
  }
}
