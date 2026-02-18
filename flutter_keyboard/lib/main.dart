import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';

import 'services/analytics_service.dart';
import 'config/app_theme.dart';
import 'config/http_overrides.dart';
import 'providers/app_state.dart';
import 'providers/user_profile_provider.dart';
import 'services/keyboard_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAF16igVSJuhwldv_kRsJ0PMmRY759X_gA',
      appId: '1:302725958482:ios:90084779f09a69bd11888b',
      messagingSenderId: '302725958482',
      projectId: 'desenrola-ia',
      storageBucket: 'desenrola-ia.firebasestorage.app',
      iosBundleId: 'com.desenrolaai.app',
    ),
  );

  runApp(const DesenrolaAIApp());
}

class DesenrolaAIApp extends StatelessWidget {
  const DesenrolaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        Provider(create: (_) => KeyboardService()),
      ],
      child: MaterialApp(
        title: 'Desenrola AI',
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
        supportedLocales: const [Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),
        routes: {
          '/login': (context) => const LoginScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }
}
