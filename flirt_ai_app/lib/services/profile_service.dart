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

  /// Atualizar nome do perfil
  Future<void> updateProfileName(String profileId, String newName) async {
    await _profilesCollection.doc(profileId).update({
      'name': newName,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Atualizar foto principal do perfil
  Future<void> updateProfileFaceImage(String profileId, String? faceImageBase64) async {
    await _profilesCollection.doc(profileId).update({
      'faceImageBase64': faceImageBase64,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Remover foto de uma plataforma (do array profileImagesBase64)
  Future<void> removeProfileImage(String profileId, PlatformType platformType, int imageIndex) async {
    final profile = await getProfile(profileId);
    if (profile == null) return;

    final platformData = profile.platforms[platformType];
    if (platformData == null) return;

    final images = platformData.profileImagesBase64;
    if (images == null || imageIndex >= images.length) return;

    final updatedImages = List<String>.from(images)..removeAt(imageIndex);

    final updatedPlatform = platformData.copyWith(
      profileImagesBase64: updatedImages,
      updatedAt: DateTime.now(),
    );

    await updatePlatform(profileId, updatedPlatform);
  }

  /// Remover foto principal de uma plataforma
  Future<void> removePlatformMainImage(String profileId, PlatformType platformType) async {
    final profile = await getProfile(profileId);
    if (profile == null) return;

    final platformData = profile.platforms[platformType];
    if (platformData == null) return;

    // Se tiver outras imagens, usar a primeira como principal
    String? newMainImage;
    List<String>? updatedImages;

    if (platformData.profileImagesBase64 != null && platformData.profileImagesBase64!.isNotEmpty) {
      newMainImage = platformData.profileImagesBase64!.first;
      updatedImages = platformData.profileImagesBase64!.sublist(1);
    }

    final updatedPlatform = PlatformData(
      type: platformData.type,
      username: platformData.username,
      bio: platformData.bio,
      age: platformData.age,
      location: platformData.location,
      occupation: platformData.occupation,
      interests: platformData.interests,
      photoDescriptions: platformData.photoDescriptions,
      openingMove: platformData.openingMove,
      prompts: platformData.prompts,
      additionalInfo: platformData.additionalInfo,
      stories: platformData.stories,
      profileImageBase64: newMainImage,
      profileImagesBase64: updatedImages,
      createdAt: platformData.createdAt,
      updatedAt: DateTime.now(),
    );

    await updatePlatform(profileId, updatedPlatform);
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
