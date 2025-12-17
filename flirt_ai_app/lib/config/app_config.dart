import 'package:flutter/foundation.dart';

/// Configurações centralizadas do app
///
/// IMPORTANTE: Atualize estas URLs antes do deploy para produção!
class AppConfig {
  // URLs do Backend (Railway)
  // Substitua pela sua URL real do Railway após o deploy
  static const String productionBackendUrl = 'https://dating-app-production-ac43.up.railway.app';
  static const String developmentBackendUrl = 'http://localhost:3000';

  // URL padrão baseada no modo
  static String get defaultBackendUrl {
    return kReleaseMode ? productionBackendUrl : developmentBackendUrl;
  }

  // Stripe Price IDs
  // Substitua pelos seus Price IDs reais da Stripe
  static const String monthlyPriceId = 'price_1SfC376A03Cc43xol5OERRUc'; // Trocar por price_xxxxx real
  static const String yearlyPriceId = 'price_1SfCBh6A03Cc43xoBU9UOlf9';   // Trocar por price_xxxxx real

  // Firebase
  static const String firebaseProjectId = 'desenrola-ia';
  static const String firebaseHostingUrl = 'https://desenrola-ia.web.app';

  // App Info
  static const String appName = 'Desenrola IA';
  static const String appVersion = '1.0.0';

  // Subscription
  static const double monthlyPrice = 29.90;
  static const double yearlyPrice = 199.90;
}
