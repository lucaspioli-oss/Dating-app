import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';
import '../../services/keyboard_service.dart';
import 'login_screen.dart';
import 'subscription_required_screen.dart';
import '../main_screen.dart';
import '../keyboard_setup_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Logged in - check subscription
        return const SubscriptionWrapper();
      },
    );
  }
}

class SubscriptionWrapper extends StatefulWidget {
  const SubscriptionWrapper({super.key});

  @override
  State<SubscriptionWrapper> createState() => _SubscriptionWrapperState();
}

class _SubscriptionWrapperState extends State<SubscriptionWrapper> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  SubscriptionStatus _status = SubscriptionStatus.inactive;
  bool _hasSeenKeyboardSetup = true; // default true to avoid flash

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      // Wait a moment to ensure Firestore is synced
      await Future.delayed(const Duration(milliseconds: 500));

      // Share auth token with keyboard extension via App Groups
      _shareAuthWithKeyboard();

      // Check if user has seen keyboard setup
      final prefs = await SharedPreferences.getInstance();
      final hasSeenSetup = prefs.getBool('hasSeenKeyboardSetup') ?? false;

      // Get current status from stream
      final status = await _subscriptionService.subscriptionStatusStream.first;

      if (mounted) {
        setState(() {
          _status = status;
          _hasSeenKeyboardSetup = hasSeenSetup;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = SubscriptionStatus.inactive;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareAuthWithKeyboard() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          final keyboardService = KeyboardService();
          await keyboardService.shareAuthWithKeyboard(token, user.uid);
        }
      }
    } catch (e) {
      // Non-critical - keyboard will fall back to BASIC mode
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ONLY allow access if status is explicitly active
    if (_status == SubscriptionStatus.active) {
      if (!_hasSeenKeyboardSetup) {
        return KeyboardSetupScreen(
          onComplete: () {
            if (mounted) {
              setState(() => _hasSeenKeyboardSetup = true);
            }
          },
        );
      }
      return const MainScreen();
    }

    // Any other status - show pricing page
    return SubscriptionRequiredScreen(status: _status);
  }
}
