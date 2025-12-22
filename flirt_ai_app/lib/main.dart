import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) 'dart:html' as html;

import 'config/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/user_profile_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/purchase_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyCNOI55N2GN0gICTRhSeY_6BFf_IfKHIgY",
            authDomain: "desenrola-ia.firebaseapp.com",
            projectId: "desenrola-ia",
            storageBucket: "desenrola-ia.firebasestorage.app",
            messagingSenderId: "302725958482",
            appId: "1:302725958482:web:9ec4b9751dba0c3611888b",
          )
        : null, // Para Android/iOS, usar google-services.json/GoogleService-Info.plist
  );

  runApp(const FlirtAIApp());
}

class FlirtAIApp extends StatelessWidget {
  const FlirtAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Desenrola AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routes: {
          '/login': (context) => const LoginScreen(),
        },
        home: Builder(
          builder: (context) {
            // Check URL on web to handle /success route
            if (kIsWeb) {
              final uri = Uri.parse(html.window.location.href);
              final path = uri.path;

              if (path.contains('/success') || path.contains('/subscription/success')) {
                final sessionId = uri.queryParameters['session_id'];
                final email = uri.queryParameters['email'];
                return PurchaseSuccessScreen(
                  sessionId: sessionId,
                  email: email,
                );
              }
            }
            return const AuthWrapper();
          },
        ),
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '');

          // Handle /success route with query params (public - no auth required)
          if (uri.path == '/success' || uri.path == '/subscription/success') {
            final sessionId = uri.queryParameters['session_id'];
            final email = uri.queryParameters['email'];
            return MaterialPageRoute(
              builder: (context) => PurchaseSuccessScreen(
                sessionId: sessionId,
                email: email,
              ),
            );
          }

          // Default route - AuthWrapper
          if (uri.path == '/' || uri.path.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            );
          }

          // Fallback to AuthWrapper
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          );
        },
      ),
    );
  }
}
