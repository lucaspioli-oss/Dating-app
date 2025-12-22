import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionService {
  static const String _baseUrl = 'https://dating-app-production-ac43.up.railway.app';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // Stream of subscription status
  Stream<SubscriptionStatus> get subscriptionStatusStream {
    if (_currentUser == null) {
      return Stream.value(SubscriptionStatus.inactive);
    }

    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return SubscriptionStatus.inactive;
      }

      final data = snapshot.data();

      // Check if user is admin/developer (stored in Firestore, not in code)
      final isAdmin = data?['isAdmin'] as bool? ?? false;
      final isDeveloper = data?['isDeveloper'] as bool? ?? false;

      if (isAdmin || isDeveloper) {
        return SubscriptionStatus.active; // Full access for admins/developers
      }

      final subscription = data?['subscription'] as Map<String, dynamic>?;

      if (subscription == null) {
        return SubscriptionStatus.inactive;
      }

      final status = subscription['status'] as String?;
      final expiresAt = (subscription['expiresAt'] as Timestamp?)?.toDate();

      if (status == 'active' && expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        return SubscriptionStatus.expired;
      }

      switch (status) {
        case 'active':
          return SubscriptionStatus.active;
        case 'cancelled':
          return SubscriptionStatus.cancelled;
        case 'expired':
          return SubscriptionStatus.expired;
        default:
          return SubscriptionStatus.inactive;
      }
    });
  }

  // Get subscription details
  Future<SubscriptionDetails?> getSubscriptionDetails() async {
    if (_currentUser == null) return null;

    final userDoc = await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .get();

    if (!userDoc.exists) return null;

    final data = userDoc.data();
    final subscription = data?['subscription'] as Map<String, dynamic>?;

    if (subscription == null) return null;

    return SubscriptionDetails(
      status: subscription['status'] as String? ?? 'inactive',
      plan: subscription['plan'] as String? ?? 'none',
      expiresAt: (subscription['expiresAt'] as Timestamp?)?.toDate(),
      stripeSubscriptionId: subscription['stripeSubscriptionId'] as String?,
      stripeCustomerId: subscription['stripeCustomerId'] as String?,
    );
  }

  // Check if feature is accessible
  Future<bool> canAccessFeature(FeatureType feature) async {
    final status = await subscriptionStatusStream.first;
    return status == SubscriptionStatus.active;
  }

  // Get days remaining in subscription/trial
  Future<int?> getDaysRemaining() async {
    final details = await getSubscriptionDetails();
    if (details?.expiresAt == null) return null;

    final now = DateTime.now();
    final difference = details!.expiresAt!.difference(now);

    return difference.inDays;
  }

  // Get formatted expiration message
  Future<String> getExpirationMessage() async {
    final details = await getSubscriptionDetails();
    if (details == null) return 'Sem assinatura ativa';

    if (details.expiresAt == null) return 'Assinatura vitalícia';

    final daysRemaining = await getDaysRemaining();
    if (daysRemaining == null) return 'Sem assinatura ativa';

    if (daysRemaining < 0) {
      return 'Expirou há ${-daysRemaining} dias';
    } else if (daysRemaining == 0) {
      return 'Expira hoje';
    } else if (daysRemaining == 1) {
      return 'Expira amanhã';
    } else if (daysRemaining <= 7) {
      return 'Expira em $daysRemaining dias';
    } else {
      return 'Expira em ${details.expiresAt!.day}/${details.expiresAt!.month}/${details.expiresAt!.year}';
    }
  }

  // Open Stripe Customer Portal for subscription management
  Future<Map<String, dynamic>> openCustomerPortal() async {
    if (_currentUser == null) {
      return {'success': false, 'error': 'Usuário não autenticado'};
    }

    try {
      final token = await _currentUser!.getIdToken();
      print('Token obtained, calling portal endpoint...');

      final response = await http.post(
        Uri.parse('$_baseUrl/create-portal-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': false, 'error': 'Resposta vazia do servidor'};
        }

        final data = json.decode(response.body);
        final portalUrl = data['url'] as String?;

        if (portalUrl == null || portalUrl.isEmpty) {
          return {'success': false, 'error': 'URL do portal não retornada'};
        }

        final uri = Uri.parse(portalUrl);

        // Try to launch URL - use platformDefault for better web compatibility
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );

        if (launched) {
          return {'success': true};
        } else {
          return {'success': false, 'error': 'Não foi possível abrir o link', 'url': portalUrl};
        }
      } else {
        String errorMessage = 'Erro no servidor: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          } catch (_) {
            errorMessage = response.body;
          }
        }
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error opening customer portal: $e');
      return {'success': false, 'error': 'Erro: $e'};
    }
  }
}

enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  inactive,
}

enum FeatureType {
  basicConversations,
  advancedPrompts,
  expertMode,
  unlimitedConversations,
}

class SubscriptionDetails {
  final String status;
  final String plan;
  final DateTime? expiresAt;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;

  SubscriptionDetails({
    required this.status,
    required this.plan,
    this.expiresAt,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
  });

  bool get isActive => status == 'active';
}
