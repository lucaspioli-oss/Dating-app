/// Configurações centralizadas do app
class AppConfig {
  // URL do Backend (Railway - Produção)
  static const String backendUrl = 'https://dating-app-production-ac43.up.railway.app';

  // Firebase
  static const String firebaseProjectId = 'desenrola-ia';
  static const String firebaseHostingUrl = 'https://desenrola-ia.web.app';

  // App Info
  static const String appName = 'Desenrola IA';
  static const String appVersion = '1.0.0';

  // Apple In-App Purchase Product IDs
  static const String appleMonthlyProductId = 'desenrola_ai_monthly';
  static const String appleQuarterlyProductId = 'desenrola_ai_quarterly';
  static const String appleYearlyProductId = 'desenrola_ai_yearly';

  static const Set<String> appleProductIds = {
    appleMonthlyProductId,
    appleQuarterlyProductId,
    appleYearlyProductId,
  };
}
