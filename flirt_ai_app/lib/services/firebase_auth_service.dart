import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      // O Cloud Function onUserCreated vai criar o documento automaticamente
      // mas vamos verificar se precisamos criar manualmente
      await _ensureUserDocument(userCredential.user!);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      // O Cloud Function onUserDeleted vai limpar os dados automaticamente
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Ensure user document exists in Firestore
  Future<void> _ensureUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Criar documento com trial de 7 dias
      final now = DateTime.now();
      final trialExpiresAt = now.add(const Duration(days: 7));

      await userDoc.set({
        'id': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'Usuário',
        'createdAt': now,
        'subscription': {
          'status': 'trial',
          'plan': 'trial',
          'expiresAt': trialExpiresAt,
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
        return 'Usuário não encontrado. Verifique o email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return e.message ?? 'Erro desconhecido: ${e.code}';
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

    if (status == 'active' && expiresAt != null) {
      return DateTime.now().isBefore(expiresAt);
    }

    // Trial também conta como ativo
    if (status == 'trial' && expiresAt != null) {
      return DateTime.now().isBefore(expiresAt);
    }

    return false;
  }
}
