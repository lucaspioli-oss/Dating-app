/// Configurações centralizadas do app
class AppConfig {
  // URL do Backend (Railway - Produção)
  static const String backendUrl = 'https://dating-app-production-ac43.up.railway.app';

  // Stripe Price IDs
  // Substitua pelos seus Price IDs reais da Stripe
  static const String monthlyPriceId = 'price_1SfC376A03Cc43xol5OERRUc';
  static const String yearlyPriceId = 'price_1SfCBh6A03Cc43xoBU9UOlf9';

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
