import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
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
    );
  }

  // Check if feature is accessible
  Future<bool> canAccessFeature(FeatureType feature) async {
    final status = await subscriptionStatusStream.first;
    return status == SubscriptionStatus.active;
  }

  // Check if user is a developer
  Future<bool> isDeveloper() async {
    if (_currentUser == null) return false;

    final userDoc = await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .get();

    if (!userDoc.exists) return false;

    final data = userDoc.data();
    return (data?['isDeveloper'] as bool? ?? false) ||
           (data?['isAdmin'] as bool? ?? false);
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

  SubscriptionDetails({
    required this.status,
    required this.plan,
    this.expiresAt,
  });

  bool get isActive => status == 'active';
}
