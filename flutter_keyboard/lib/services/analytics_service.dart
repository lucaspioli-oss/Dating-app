import 'package:flutter/material.dart';

/// Analytics service - placeholder after Firebase Analytics removal
/// Can be replaced with Supabase analytics, Mixpanel, or other service
class AnalyticsService {
  static NavigatorObserver get observer => NavigatorObserver();

  static Future<void> logProfileCreated(String platform) async {}
  static Future<void> logSuggestionGenerated(String tone) async {}
  static Future<void> logSubscriptionViewed() async {}
  static Future<void> logKeyboardUsed() async {}
  static Future<void> logContactImported() async {}
  static Future<void> logConversationCreated(String platform) async {}
}
