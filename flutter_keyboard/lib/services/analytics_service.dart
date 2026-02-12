import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logProfileCreated(String platform) async {
    await _analytics.logEvent(
      name: 'profile_created',
      parameters: {'platform': platform},
    );
  }

  static Future<void> logSuggestionGenerated(String tone) async {
    await _analytics.logEvent(
      name: 'suggestion_generated',
      parameters: {'tone': tone},
    );
  }

  static Future<void> logSubscriptionViewed() async {
    await _analytics.logEvent(name: 'subscription_viewed');
  }

  static Future<void> logKeyboardUsed() async {
    await _analytics.logEvent(name: 'keyboard_used');
  }

  static Future<void> logContactImported() async {
    await _analytics.logEvent(name: 'whatsapp_contact_imported');
  }

  static Future<void> logConversationCreated(String platform) async {
    await _analytics.logEvent(
      name: 'conversation_created',
      parameters: {'platform': platform},
    );
  }
}
