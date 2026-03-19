import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';
import '../../services/keyboard_service.dart';
import '../../widgets/app_loading.dart';
import 'login_screen.dart';
import 'subscription_required_screen.dart';
import '../main_screen.dart';
import '../keyboard_setup_screen.dart';
import '../app_tutorial_screen.dart';
import '../onboarding/onboarding_profile_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingScreen();
        }

        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }

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

class _SubscriptionWrapperState extends State<SubscriptionWrapper> with WidgetsBindingObserver {
  final SubscriptionService _subscriptionService = SubscriptionService();
  Timer? _tokenRefreshTimer;
  bool _isLoading = true;
  SubscriptionStatus _status = SubscriptionStatus.inactive;
  bool _hasCompletedOnboarding = true;
  bool _hasSeenKeyboardSetup = true;
  bool _hasSeenAppTutorial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for auth state changes and re-share with keyboard
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) _shareAuthWithKeyboard();
    });

    // Refresh token sharing periodically
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 45),
      (_) => _shareAuthWithKeyboard(),
    );

    _checkSubscription();
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _shareAuthWithKeyboard();
    }
  }

  Future<void> _checkSubscription() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _shareAuthWithKeyboard();

      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboardingProfile') ?? false;
      final hasSeenSetup = prefs.getBool('hasSeenKeyboardSetup') ?? false;
      final hasSeenTutorial = prefs.getBool('hasSeenAppTutorial') ?? false;

      final status = await _subscriptionService.subscriptionStatusStream.first;

      if (mounted) {
        setState(() {
          _status = status;
          _hasCompletedOnboarding = hasCompletedOnboarding;
          _hasSeenKeyboardSetup = hasSeenSetup;
          _hasSeenAppTutorial = hasSeenTutorial;
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
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final keyboardService = KeyboardService();
        await keyboardService.shareAuthWithKeyboard(
          session.accessToken,
          session.user.id,
        );
      }
    } catch (e) {
      // Non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingScreen();
    }

    if (!_hasCompletedOnboarding) {
      return OnboardingProfileScreen(
        onComplete: () {
          if (mounted) setState(() => _hasCompletedOnboarding = true);
        },
      );
    }
    if (!_hasSeenKeyboardSetup) {
      return KeyboardSetupScreen(
        onComplete: () {
          if (mounted) setState(() => _hasSeenKeyboardSetup = true);
        },
      );
    }
    if (!_hasSeenAppTutorial) {
      return AppTutorialScreen(
        onComplete: () {
          if (mounted) setState(() => _hasSeenAppTutorial = true);
        },
      );
    }
    return const MainScreen();
  }
}
