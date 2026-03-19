import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Buscar todos os perfis do usuario (realtime stream)
  Stream<List<Profile>> getProfiles(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          final profiles = rows.map((row) => Profile.fromSupabase(row)).toList();
          profiles.sort((a, b) {
            final aDate = a.lastActivityAt ?? a.updatedAt;
            final bDate = b.lastActivityAt ?? b.updatedAt;
            return bDate.compareTo(aDate);
          });
          return profiles;
        });
  }

  /// Buscar perfil por ID
  Future<Profile?> getProfile(String profileId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromSupabase(data);
  }

  /// Criar novo perfil
  Future<Profile> createProfile({
    required String userId,
    required String name,
    String? faceDescription,
    String? faceImageBase64,
    required PlatformData initialPlatform,
  }) async {
    final now = DateTime.now().toIso8601String();

    final profileData = {
      'user_id': userId,
      'name': name,
      'face_image_base64': faceImageBase64,
      'platforms': {
        initialPlatform.type.name: initialPlatform.toMap(),
      },
      'created_at': now,
      'updated_at': now,
    };

    final result = await _supabase
        .from('profiles')
        .insert(profileData)
        .select()
        .single();

    return Profile.fromSupabase(result);
  }

  /// Atualizar perfil
  Future<void> updateProfile(Profile profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await _supabase
        .from('profiles')
        .update(updatedProfile.toSupabaseMap())
        .eq('id', profile.id);
  }

  /// Adicionar plataforma ao perfil
  Future<void> addPlatform(String profileId, PlatformData platform) async {
    final current = await getProfile(profileId);
    if (current == null) return;

    final platforms = current.platformsMap;
    platforms[platform.type.name] = platform.toMap();

    await _supabase.from('profiles').update({
      'platforms': platforms,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profileId);
  }

  /// Atualizar dados de uma plataforma
  Future<void> updatePlatform(String profileId, PlatformData platform) async {
    final current = await getProfile(profileId);
    if (current == null) return;

    final platforms = current.platformsMap;
    platforms[platform.type.name] = platform.toMap();

    await _supabase.from('profiles').update({
      'platforms': platforms,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profileId);
  }

  /// Remover plataforma do perfil
  Future<void> removePlatform(String profileId, PlatformType type) async {
    final current = await getProfile(profileId);
    if (current == null) return;

    final platforms = current.platformsMap;
    platforms.remove(type.name);

    await _supabase.from('profiles').update({
      'platforms': platforms,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profileId);
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
    await _supabase.from('profiles').delete().eq('id', profileId);
  }

  /// Buscar perfil por nome (para evitar duplicatas)
  Future<Profile?> findProfileByName(String userId, String name) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .eq('name', name)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromSupabase(data);
  }
}
