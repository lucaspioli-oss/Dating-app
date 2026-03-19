import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get _currentUser => _supabase.auth.currentUser;

  // Stream of subscription status (realtime)
  Stream<SubscriptionStatus> get subscriptionStatusStream {
    if (_currentUser == null) {
      return Stream.value(SubscriptionStatus.inactive);
    }

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', _currentUser!.id)
        .map((rows) {
      if (rows.isEmpty) return SubscriptionStatus.inactive;

      final data = rows.first;

      final isAdmin = data['is_admin'] as bool? ?? false;
      final isDeveloper = data['is_developer'] as bool? ?? false;

      if (isAdmin || isDeveloper) return SubscriptionStatus.active;

      final status = data['subscription_status'] as String?;
      final expiresAtStr = data['subscription_expires_at'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

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

    final data = await _supabase
        .from('users')
        .select('subscription_status, subscription_plan, subscription_expires_at')
        .eq('id', _currentUser!.id)
        .maybeSingle();

    if (data == null) return null;

    final expiresAtStr = data['subscription_expires_at'] as String?;

    return SubscriptionDetails(
      status: data['subscription_status'] as String? ?? 'inactive',
      plan: data['subscription_plan'] as String? ?? 'none',
      expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
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

    final data = await _supabase
        .from('users')
        .select('is_developer, is_admin')
        .eq('id', _currentUser!.id)
        .maybeSingle();

    if (data == null) return false;
    return (data['is_developer'] as bool? ?? false) ||
           (data['is_admin'] as bool? ?? false);
  }

  // Get days remaining in subscription
  Future<int?> getDaysRemaining() async {
    final details = await getSubscriptionDetails();
    if (details?.expiresAt == null) return null;
    return details!.expiresAt!.difference(DateTime.now()).inDays;
  }

  // Get formatted expiration message
  Future<String> getExpirationMessage() async {
    final details = await getSubscriptionDetails();
    if (details == null) return 'Sem assinatura ativa';
    if (details.expiresAt == null) return 'Assinatura vitalicia';

    final daysRemaining = await getDaysRemaining();
    if (daysRemaining == null) return 'Sem assinatura ativa';

    if (daysRemaining < 0) return 'Expirou ha ${-daysRemaining} dias';
    if (daysRemaining == 0) return 'Expira hoje';
    if (daysRemaining == 1) return 'Expira amanha';
    if (daysRemaining <= 7) return 'Expira em $daysRemaining dias';
    return 'Expira em ${details.expiresAt!.day}/${details.expiresAt!.month}/${details.expiresAt!.year}';
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
