import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Manages free-tier daily usage limits.
///
/// Non-subscribers get [maxFreeUsesPerDay] AI suggestions per calendar day.
/// The counter auto-resets at midnight (device local time).
class FreemiumService {
  static const int maxFreeUsesPerDay = 5;
  static const String _keyPrefix = 'freemium_uses_';

  /// Returns the SharedPreferences key for today.
  static String _todayKey() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return '$_keyPrefix$today';
  }

  /// How many free uses remain today.
  Future<int> getRemainingFreeUses() async {
    final used = await getDailyUsageCount();
    final remaining = maxFreeUsesPerDay - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Record one AI suggestion usage.
  Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Whether the user still has free uses available today.
  Future<bool> canUseFreeAI() async {
    final remaining = await getRemainingFreeUses();
    return remaining > 0;
  }

  /// Cleans up stale keys from previous days.
  /// Call this on app start to keep SharedPreferences tidy.
  Future<void> resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final allKeys = prefs.getKeys();

    for (final key in allKeys) {
      if (key.startsWith(_keyPrefix) && key != todayKey) {
        await prefs.remove(key);
      }
    }
  }

  /// Number of AI suggestions used today.
  Future<int> getDailyUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayKey()) ?? 0;
  }
}
