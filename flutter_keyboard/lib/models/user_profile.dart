class UserProfile {
  final String name;
  final int age;
  final String gender;
  final List<String> interests;
  final List<String> dislikes;
  final String humorStyle;
  final String relationshipGoal;
  final String preferredTone;
  final String bio;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    required this.dislikes,
    required this.humorStyle,
    required this.relationshipGoal,
    required this.preferredTone,
    this.bio = '',
  });

  // Construtor vazio para inicialização
  factory UserProfile.empty() {
    return UserProfile(
      name: '',
      age: 18,
      gender: 'Prefiro não dizer',
      interests: [],
      dislikes: [],
      humorStyle: 'casual',
      relationshipGoal: 'conhecer pessoas',
      preferredTone: 'casual',
      bio: '',
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'interests': interests,
      'dislikes': dislikes,
      'humorStyle': humorStyle,
      'relationshipGoal': relationshipGoal,
      'preferredTone': preferredTone,
      'bio': bio,
    };
  }

  // Criar a partir de JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 18,
      gender: json['gender'] ?? 'Prefiro não dizer',
      interests: List<String>.from(json['interests'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
      humorStyle: json['humorStyle'] ?? 'casual',
      relationshipGoal: json['relationshipGoal'] ?? 'conhecer pessoas',
      preferredTone: json['preferredTone'] ?? 'casual',
      bio: json['bio'] ?? '',
    );
  }

  // Copiar com modificações
  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    List<String>? interests,
    List<String>? dislikes,
    String? humorStyle,
    String? relationshipGoal,
    String? preferredTone,
    String? bio,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      dislikes: dislikes ?? this.dislikes,
      humorStyle: humorStyle ?? this.humorStyle,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      preferredTone: preferredTone ?? this.preferredTone,
      bio: bio ?? this.bio,
    );
  }

  // Verificar se o perfil está completo
  bool get isComplete {
    return name.isNotEmpty &&
           interests.isNotEmpty &&
           age >= 18;
  }

  // Gerar contexto para a IA
  String toAIContext() {
    final buffer = StringBuffer();

    buffer.writeln('Perfil do usuário:');
    buffer.writeln('- Nome: $name');
    buffer.writeln('- Idade: $age anos');
    buffer.writeln('- Gênero: $gender');

    if (interests.isNotEmpty) {
      buffer.writeln('- Interesses: ${interests.join(', ')}');
    }

    if (dislikes.isNotEmpty) {
      buffer.writeln('- Não gosta de: ${dislikes.join(', ')}');
    }

    buffer.writeln('- Estilo de humor: $humorStyle');
    buffer.writeln('- Objetivo: $relationshipGoal');
    buffer.writeln('- Tom preferido: $preferredTone');

    if (bio.isNotEmpty) {
      buffer.writeln('- Sobre: $bio');
    }

    return buffer.toString();
  }
}
