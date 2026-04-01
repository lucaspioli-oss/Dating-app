import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';

import 'services/analytics_service.dart';
import 'services/error_reporter.dart';
import 'config/app_theme.dart';
import 'config/http_overrides.dart';
import 'providers/app_state.dart';
import 'providers/user_profile_provider.dart';
import 'services/keyboard_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/screenshot_analyze_screen.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  ErrorReporter.init();

  runApp(const DesenrolaAIApp());
}

class DesenrolaAIApp extends StatelessWidget {
  const DesenrolaAIApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        Provider(create: (_) => KeyboardService()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          // Handle deep link navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final link = appState.pendingDeepLink;
            if (link != null && link.contains('analyze-screenshot')) {
              appState.clearPendingDeepLink();
              navigatorKey.currentState?.pushNamed('/analyze-screenshot');
            }
          });

          return MaterialApp(
            title: 'Desenrola AI',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [AnalyticsService.observer],
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'),
              Locale('en'),
              Locale('es'),
            ],
            locale: appState.locale,
            routes: {
              '/login': (context) => const LoginScreen(),
              '/analyze-screenshot': (context) => const ScreenshotAnalyzeScreen(),
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
