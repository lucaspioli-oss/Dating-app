import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Tenta criar documento no Firestore, mas não falha se der erro
      // (o documento pode ser criado por Cloud Function ou na primeira verificação)
      try {
        await _ensureUserDocument(userCredential.user!);
      } catch (firestoreError) {
        // Ignora erro do Firestore - usuário foi criado com sucesso
        print('Aviso: Erro ao criar documento Firestore: $firestoreError');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('email-already-in-use') || message.contains('already in use')) {
        throw 'Este email já está cadastrado.';
      }
      if (message.contains('weak-password') || message.contains('weak password')) {
        throw 'A senha deve ter no mínimo 6 caracteres.';
      }
      if (message.contains('invalid-email') || message.contains('invalid email')) {
        throw 'Email inválido.';
      }
      throw 'Erro ao criar conta. Tente novamente.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Captura outros tipos de exceção e trata a mensagem
      final message = e.toString().toLowerCase();
      if (message.contains('credential') ||
          message.contains('password') ||
          message.contains('user') ||
          message.contains('malformed') ||
          message.contains('expired')) {
        throw 'Usuário ou senha incorretos.';
      }
      throw 'Erro ao fazer login. Tente novamente.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account and all associated data (GDPR)
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');
      // Call server endpoint to delete all user data first (while we still have a valid token)
      final token = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('${AppConfig.backendUrl}/user/account'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete account data: ${response.body}');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Ensure user document exists in Firestore
  Future<void> _ensureUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      final now = DateTime.now();

      await userDoc.set({
        'id': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'Usuário',
        'createdAt': now,
        'subscription': {
          'status': 'inactive',
          'plan': 'none',
        },
        'stats': {
          'totalConversations': 0,
          'totalMessages': 0,
          'aiSuggestionsUsed': 0,
        },
      });

      // Create analytics document
      await _firestore.collection('analytics').doc(user.uid).set({
        'userId': user.uid,
        'signupDate': now,
        'lastActive': now,
        'conversationQualityHistory': [],
      });
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email já está cadastrado. Faça login ou recupere sua senha.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email ou senha incorretos.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        // Para erros de login, mostrar mensagem genérica
        if (e.code.contains('credential') || e.code.contains('password') || e.code.contains('user')) {
          return 'Email ou senha incorretos.';
        }
        return 'Erro ao processar. Tente novamente.';
    }
  }

  // Get user subscription status from Firestore
  Future<Map<String, dynamic>?> getUserSubscription() async {
    if (currentUser == null) return null;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!userDoc.exists) return null;

    return userDoc.data()?['subscription'] as Map<String, dynamic>?;
  }

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final subscription = await getUserSubscription();
    if (subscription == null) return false;

    final status = subscription['status'] as String?;
    final expiresAt = (subscription['expiresAt'] as Timestamp?)?.toDate();

    if (status == 'active') {
      if (expiresAt == null) return true;
      return DateTime.now().isBefore(expiresAt);
    }

    return false;
  }
}
