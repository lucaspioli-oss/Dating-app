import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Coleção de perfis
  CollectionReference<Map<String, dynamic>> get _profilesCollection =>
      _firestore.collection('profiles');

  /// Buscar todos os perfis do usuário
  Stream<List<Profile>> getProfiles(String userId) {
    return _profilesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Profile.fromFirestore(doc)).toList());
  }

  /// Buscar perfil por ID
  Future<Profile?> getProfile(String profileId) async {
    final doc = await _profilesCollection.doc(profileId).get();
    if (!doc.exists) return null;
    return Profile.fromFirestore(doc);
  }

  /// Criar novo perfil
  Future<Profile> createProfile({
    required String userId,
    required String name,
    String? faceDescription,
    String? faceImageBase64,
    required PlatformData initialPlatform,
  }) async {
    final now = DateTime.now();

    final profileData = {
      'userId': userId,
      'name': name,
      'faceDescription': faceDescription,
      'faceImageBase64': faceImageBase64,
      'platforms': {
        initialPlatform.type.name: initialPlatform.toMap(),
      },
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final docRef = await _profilesCollection.add(profileData);

    return Profile(
      id: docRef.id,
      userId: userId,
      name: name,
      faceDescription: faceDescription,
      faceImageBase64: faceImageBase64,
      platforms: {initialPlatform.type: initialPlatform},
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Atualizar perfil
  Future<void> updateProfile(Profile profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await _profilesCollection.doc(profile.id).update(updatedProfile.toMap());
  }

  /// Adicionar plataforma ao perfil
  Future<void> addPlatform(String profileId, PlatformData platform) async {
    await _profilesCollection.doc(profileId).update({
      'platforms.${platform.type.name}': platform.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Atualizar dados de uma plataforma
  Future<void> updatePlatform(String profileId, PlatformData platform) async {
    await _profilesCollection.doc(profileId).update({
      'platforms.${platform.type.name}': platform.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Remover plataforma do perfil
  Future<void> removePlatform(String profileId, PlatformType type) async {
    await _profilesCollection.doc(profileId).update({
      'platforms.${type.name}': FieldValue.delete(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Adicionar story ao Instagram
  Future<void> addStory(String profileId, StoryData story) async {
    final profile = await getProfile(profileId);
    if (profile == null) return;

    final instagram = profile.instagram;
    if (instagram == null) return;

    final List<StoryData> updatedStories = [...(instagram.stories ?? []), story];
    final updatedInstagram = instagram.copyWith(
      stories: updatedStories,
      updatedAt: DateTime.now(),
    );

    await updatePlatform(profileId, updatedInstagram);
  }

  /// Remover story do Instagram
  Future<void> removeStory(String profileId, String storyId) async {
    final profile = await getProfile(profileId);
    if (profile == null) return;

    final instagram = profile.instagram;
    if (instagram == null) return;

    final List<StoryData> updatedStories =
        instagram.stories?.where((s) => s.id != storyId).toList() ?? [];
    final updatedInstagram = instagram.copyWith(
      stories: updatedStories,
      updatedAt: DateTime.now(),
    );

    await updatePlatform(profileId, updatedInstagram);
  }

  /// Limpar todos os stories
  Future<void> clearStories(String profileId) async {
    final profile = await getProfile(profileId);
    if (profile == null) return;

    final instagram = profile.instagram;
    if (instagram == null) return;

    final updatedInstagram = instagram.copyWith(
      stories: [],
      updatedAt: DateTime.now(),
    );

    await updatePlatform(profileId, updatedInstagram);
  }

  /// Deletar perfil
  Future<void> deleteProfile(String profileId) async {
    await _profilesCollection.doc(profileId).delete();
  }

  /// Buscar perfil por nome (para evitar duplicatas)
  Future<Profile?> findProfileByName(String userId, String name) async {
    final snapshot = await _profilesCollection
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Profile.fromFirestore(snapshot.docs.first);
  }
}
