import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class FirebaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Current user stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign up with email and password
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': displayName},
      );

      if (response.user != null) {
        try {
          await _ensureUserDocument(response.user!);
        } catch (e) {
          print('Aviso: Erro ao criar documento do usuario: $e');
        }
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('already') || message.contains('exists')) {
        throw 'Este email ja esta cadastrado.';
      }
      if (message.contains('weak') || message.contains('password')) {
        throw 'A senha deve ter no minimo 6 caracteres.';
      }
      if (message.contains('invalid') && message.contains('email')) {
        throw 'Email invalido.';
      }
      throw 'Erro ao criar conta. Tente novamente.';
    }
  }

  // Sign in with email and password
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('credential') ||
          message.contains('password') ||
          message.contains('user') ||
          message.contains('invalid')) {
        throw 'Usuario ou senha incorretos.';
      }
      throw 'Erro ao fazer login. Tente novamente.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification (Supabase handles this automatically on signup)
  Future<void> sendEmailVerification() async {
    // Supabase sends verification email automatically on signup
    // Can be re-triggered via resend
    final user = currentUser;
    if (user?.email != null) {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user!.email!,
      );
    }
  }

  // Delete account and all associated data (GDPR)
  Future<void> deleteAccount() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('No user logged in');

      final response = await http.delete(
        Uri.parse('${AppConfig.backendUrl}/user/account'),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete account data: ${response.body}');
      }
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Ensure user document exists in users table
  Future<void> _ensureUserDocument(User user) async {
    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['full_name'] ?? 'Usuario',
        'subscription_status': 'inactive',
        'subscription_plan': 'none',
        'is_admin': false,
        'is_developer': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('analytics').upsert({
        'user_id': user.id,
        'signup_date': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
        'conversation_quality_history': [],
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Handle auth exceptions
  String _handleAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('email') && msg.contains('already')) {
      return 'Este email ja esta cadastrado. Faca login ou recupere sua senha.';
    }
    if (msg.contains('invalid') && msg.contains('email')) {
      return 'Email invalido.';
    }
    if (msg.contains('invalid') || msg.contains('credentials') || msg.contains('password')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('disabled') || msg.contains('banned')) {
      return 'Esta conta foi desativada.';
    }
    if (msg.contains('rate') || msg.contains('too many')) {
      return 'Muitas tentativas. Tente novamente mais tarde.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Erro de conexao. Verifique sua internet.';
    }
    return 'Erro ao processar. Tente novamente.';
  }

  // Get user subscription status
  Future<Map<String, dynamic>?> getUserSubscription() async {
    if (currentUser == null) return null;

    final data = await _supabase
        .from('users')
        .select('subscription_status, subscription_plan, subscription_expires_at')
        .eq('id', currentUser!.id)
        .maybeSingle();

    if (data == null) return null;

    return {
      'status': data['subscription_status'],
      'plan': data['subscription_plan'],
      'expiresAt': data['subscription_expires_at'],
    };
  }

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final subscription = await getUserSubscription();
    if (subscription == null) return false;

    final status = subscription['status'] as String?;
    final expiresAtStr = subscription['expiresAt'] as String?;

    if (status == 'active') {
      if (expiresAtStr == null) return true;
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null) return true;
      return DateTime.now().isBefore(expiresAt);
    }

    return false;
  }
}
