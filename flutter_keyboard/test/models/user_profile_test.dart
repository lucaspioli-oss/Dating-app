import 'package:flutter_test/flutter_test.dart';
import 'package:desenrola_ai_keyboard/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('empty() creates profile with default values', () {
      final profile = UserProfile.empty();
      expect(profile.name, '');
      expect(profile.age, 18);
      expect(profile.gender, 'Prefiro não dizer');
      expect(profile.interests, isEmpty);
      expect(profile.dislikes, isEmpty);
      expect(profile.humorStyle, 'casual');
      expect(profile.relationshipGoal, 'conhecer pessoas');
      expect(profile.preferredTone, 'casual');
      expect(profile.bio, '');
    });

    group('isComplete', () {
      test('returns false for empty profile', () {
        final profile = UserProfile.empty();
        expect(profile.isComplete, isFalse);
      });

      test('returns false when name is empty', () {
        final profile = UserProfile(
          name: '',
          age: 25,
          gender: 'Masculino',
          interests: ['música'],
          dislikes: [],
          humorStyle: 'casual',
          relationshipGoal: 'namoro',
          preferredTone: 'casual',
        );
        expect(profile.isComplete, isFalse);
      });

      test('returns false when interests are empty', () {
        final profile = UserProfile(
          name: 'Lucas',
          age: 25,
          gender: 'Masculino',
          interests: [],
          dislikes: [],
          humorStyle: 'casual',
          relationshipGoal: 'namoro',
          preferredTone: 'casual',
        );
        expect(profile.isComplete, isFalse);
      });

      test('returns false when age < 18', () {
        final profile = UserProfile(
          name: 'Lucas',
          age: 17,
          gender: 'Masculino',
          interests: ['música'],
          dislikes: [],
          humorStyle: 'casual',
          relationshipGoal: 'namoro',
          preferredTone: 'casual',
        );
        expect(profile.isComplete, isFalse);
      });

      test('returns true when name, interests, and age >= 18', () {
        final profile = UserProfile(
          name: 'Lucas',
          age: 25,
          gender: 'Masculino',
          interests: ['música', 'esportes'],
          dislikes: [],
          humorStyle: 'casual',
          relationshipGoal: 'namoro',
          preferredTone: 'casual',
        );
        expect(profile.isComplete, isTrue);
      });
    });

    group('toJson / fromJson', () {
      test('round-trip preserves all fields', () {
        final original = UserProfile(
          name: 'Maria',
          age: 22,
          gender: 'Feminino',
          interests: ['música', 'viagem'],
          dislikes: ['fofoca'],
          humorStyle: 'sarcástico',
          relationshipGoal: 'namoro sério',
          preferredTone: 'ousado',
          bio: 'Amo viajar',
        );

        final json = original.toJson();
        final restored = UserProfile.fromJson(json);

        expect(restored.name, original.name);
        expect(restored.age, original.age);
        expect(restored.gender, original.gender);
        expect(restored.interests, original.interests);
        expect(restored.dislikes, original.dislikes);
        expect(restored.humorStyle, original.humorStyle);
        expect(restored.relationshipGoal, original.relationshipGoal);
        expect(restored.preferredTone, original.preferredTone);
        expect(restored.bio, original.bio);
      });

      test('fromJson handles missing fields with defaults', () {
        final profile = UserProfile.fromJson({});
        expect(profile.name, '');
        expect(profile.age, 18);
        expect(profile.gender, 'Prefiro não dizer');
        expect(profile.interests, isEmpty);
        expect(profile.dislikes, isEmpty);
        expect(profile.humorStyle, 'casual');
        expect(profile.relationshipGoal, 'conhecer pessoas');
        expect(profile.preferredTone, 'casual');
        expect(profile.bio, '');
      });

      test('toJson includes all fields', () {
        final profile = UserProfile(
          name: 'Test',
          age: 20,
          gender: 'Masculino',
          interests: ['a'],
          dislikes: ['b'],
          humorStyle: 'h',
          relationshipGoal: 'r',
          preferredTone: 't',
          bio: 'bio',
        );
        final json = profile.toJson();
        expect(json, containsPair('name', 'Test'));
        expect(json, containsPair('age', 20));
        expect(json, containsPair('gender', 'Masculino'));
        expect(json, containsPair('interests', ['a']));
        expect(json, containsPair('dislikes', ['b']));
        expect(json, containsPair('humorStyle', 'h'));
        expect(json, containsPair('relationshipGoal', 'r'));
        expect(json, containsPair('preferredTone', 't'));
        expect(json, containsPair('bio', 'bio'));
      });
    });

    group('copyWith', () {
      test('copies all fields when none specified', () {
        final original = UserProfile(
          name: 'Lucas',
          age: 25,
          gender: 'Masculino',
          interests: ['música'],
          dislikes: ['fofoca'],
          humorStyle: 'casual',
          relationshipGoal: 'namoro',
          preferredTone: 'casual',
          bio: 'Olá',
        );
        final copy = original.copyWith();

        expect(copy.name, original.name);
        expect(copy.age, original.age);
        expect(copy.gender, original.gender);
        expect(copy.interests, original.interests);
        expect(copy.bio, original.bio);
      });

      test('overrides only specified fields', () {
        final original = UserProfile.empty();
        final modified = original.copyWith(name: 'João', age: 30);

        expect(modified.name, 'João');
        expect(modified.age, 30);
        expect(modified.gender, original.gender);
        expect(modified.interests, original.interests);
      });
    });

    group('toAIContext', () {
      test('includes basic fields', () {
        final profile = UserProfile(
          name: 'Lucas',
          age: 25,
          gender: 'Masculino',
          interests: ['música', 'cinema'],
          dislikes: [],
          humorStyle: 'engraçado',
          relationshipGoal: 'namoro',
          preferredTone: 'ousado',
        );
        final context = profile.toAIContext();
        expect(context, contains('Lucas'));
        expect(context, contains('25'));
        expect(context, contains('Masculino'));
        expect(context, contains('música, cinema'));
        expect(context, contains('engraçado'));
        expect(context, contains('namoro'));
        expect(context, contains('ousado'));
      });

      test('omits empty dislikes', () {
        final profile = UserProfile(
          name: 'X',
          age: 18,
          gender: 'X',
          interests: ['a'],
          dislikes: [],
          humorStyle: 'h',
          relationshipGoal: 'r',
          preferredTone: 't',
        );
        expect(profile.toAIContext(), isNot(contains('Não gosta de')));
      });

      test('includes dislikes when present', () {
        final profile = UserProfile(
          name: 'X',
          age: 18,
          gender: 'X',
          interests: ['a'],
          dislikes: ['política'],
          humorStyle: 'h',
          relationshipGoal: 'r',
          preferredTone: 't',
        );
        expect(profile.toAIContext(), contains('política'));
      });

      test('includes bio when not empty', () {
        final profile = UserProfile(
          name: 'X',
          age: 18,
          gender: 'X',
          interests: ['a'],
          dislikes: [],
          humorStyle: 'h',
          relationshipGoal: 'r',
          preferredTone: 't',
          bio: 'Sou aventureiro',
        );
        expect(profile.toAIContext(), contains('Sou aventureiro'));
      });

      test('omits bio when empty', () {
        final profile = UserProfile(
          name: 'X',
          age: 18,
          gender: 'X',
          interests: ['a'],
          dislikes: [],
          humorStyle: 'h',
          relationshipGoal: 'r',
          preferredTone: 't',
          bio: '',
        );
        expect(profile.toAIContext(), isNot(contains('Sobre:')));
      });
    });
  });
}
