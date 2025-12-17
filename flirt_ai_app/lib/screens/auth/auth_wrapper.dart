import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';
import 'login_screen.dart';
import 'subscription_required_screen.dart';
import '../main_screen.dart';

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

class SubscriptionWrapper extends StatelessWidget {
  const SubscriptionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService();

    return StreamBuilder<SubscriptionStatus>(
      stream: subscriptionService.subscriptionStatusStream,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final status = snapshot.data ?? SubscriptionStatus.inactive;

        // Check if subscription is active
        if (status == SubscriptionStatus.active) {
          return const MainScreen();
        }

        // No active subscription - show pricing page
        return SubscriptionRequiredScreen(status: status);
      },
    );
  }
}
