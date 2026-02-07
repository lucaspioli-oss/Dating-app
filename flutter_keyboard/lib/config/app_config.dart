/// Configurações centralizadas do app
class AppConfig {
  // URL do Backend (Railway - Produção)
  static const String backendUrl = 'https://dating-app-production-ac43.up.railway.app';

  // Stripe Configuration
  static const String stripePublishableKey = 'pk_live_51SgqkDAflPjpW4DOCQ8ALttsKXKFJKSnf4vCETfk8TEhHDpeLnd0vQOVXiKLun5BB06AHnzj8WWpUKxd6N7FYEvb00im6X7YSh';

  // Stripe Price IDs (Live)
  static const String monthlyPriceId = 'price_1SgsCVAflPjpW4DOXIZVjcA4';
  static const String quarterlyPriceId = 'price_1SgsmgAflPjpW4DO0oID3xaW';
  static const String yearlyPriceId = 'price_1SgsESAflPjpW4DO6Sd4z8n0';

  // Firebase
  static const String firebaseProjectId = 'desenrola-ia';
  static const String firebaseHostingUrl = 'https://desenrola-ia.web.app';

  // App Info
  static const String appName = 'Desenrola IA';
  static const String appVersion = '1.0.0';

  // Subscription Prices
  static const double monthlyPrice = 29.90;
  static const double quarterlyPrice = 69.90;
  static const double yearlyPrice = 199.90;

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
