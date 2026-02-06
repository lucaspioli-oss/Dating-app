import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile.empty();
  bool _isLoading = false;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isProfileComplete => _profile.isComplete;

  UserProfileProvider() {
    _loadProfile();
  }

  // Carregar perfil do SharedPreferences
  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');

      if (profileJson != null) {
        final Map<String, dynamic> data = jsonDecode(profileJson);
        _profile = UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Salvar perfil no SharedPreferences
  Future<void> saveProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = profile;
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString('user_profile', profileJson);

      debugPrint('Perfil salvo com sucesso!');
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualizar campos específicos
  Future<void> updateName(String name) async {
    await saveProfile(_profile.copyWith(name: name));
  }

  Future<void> updateAge(int age) async {
    await saveProfile(_profile.copyWith(age: age));
  }

  Future<void> updateGender(String gender) async {
    await saveProfile(_profile.copyWith(gender: gender));
  }

  Future<void> updateInterests(List<String> interests) async {
    await saveProfile(_profile.copyWith(interests: interests));
  }

  Future<void> updateDislikes(List<String> dislikes) async {
    await saveProfile(_profile.copyWith(dislikes: dislikes));
  }

  Future<void> updateHumorStyle(String humorStyle) async {
    await saveProfile(_profile.copyWith(humorStyle: humorStyle));
  }

  Future<void> updateRelationshipGoal(String goal) async {
    await saveProfile(_profile.copyWith(relationshipGoal: goal));
  }

  Future<void> updatePreferredTone(String tone) async {
    await saveProfile(_profile.copyWith(preferredTone: tone));
  }

  Future<void> updateBio(String bio) async {
    await saveProfile(_profile.copyWith(bio: bio));
  }

  // Limpar perfil
  Future<void> clearProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = UserProfile.empty();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
    } catch (e) {
      debugPrint('Erro ao limpar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
