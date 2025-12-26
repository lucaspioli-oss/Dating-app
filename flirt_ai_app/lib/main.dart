import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/app_theme.dart';
import 'utils/web_url_helper.dart';
import 'providers/app_state.dart';
import 'providers/user_profile_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/purchase_success_screen.dart';
import 'screens/embedded_checkout_screen.dart';

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
            // Check URL on web to handle public routes
            if (kIsWeb) {
              final uri = WebUrlHelper.getCurrentUri();
              final path = uri?.path ?? '';

              // Handle /checkout route
              if (path.contains('/checkout') && uri != null) {
                final plan = uri.queryParameters['plan'];
                final email = uri.queryParameters['email'];
                // Capture UTM parameters
                final utmSource = uri.queryParameters['utm_source'];
                final utmMedium = uri.queryParameters['utm_medium'];
                final utmCampaign = uri.queryParameters['utm_campaign'];
                final utmContent = uri.queryParameters['utm_content'];
                final utmTerm = uri.queryParameters['utm_term'];
                return EmbeddedCheckoutScreen(
                  plan: plan,
                  email: email,
                  utmSource: utmSource,
                  utmMedium: utmMedium,
                  utmCampaign: utmCampaign,
                  utmContent: utmContent,
                  utmTerm: utmTerm,
                );
              }

              // Handle /success route
              if ((path.contains('/success') || path.contains('/subscription/success')) && uri != null) {
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

          // Handle /checkout route (public - for embedded checkout)
          if (uri.path == '/checkout') {
            final plan = uri.queryParameters['plan'];
            final email = uri.queryParameters['email'];
            final utmSource = uri.queryParameters['utm_source'];
            final utmMedium = uri.queryParameters['utm_medium'];
            final utmCampaign = uri.queryParameters['utm_campaign'];
            final utmContent = uri.queryParameters['utm_content'];
            final utmTerm = uri.queryParameters['utm_term'];
            return MaterialPageRoute(
              builder: (context) => EmbeddedCheckoutScreen(
                plan: plan,
                email: email,
                utmSource: utmSource,
                utmMedium: utmMedium,
                utmCampaign: utmCampaign,
                utmContent: utmContent,
                utmTerm: utmTerm,
              ),
            );
          }

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
