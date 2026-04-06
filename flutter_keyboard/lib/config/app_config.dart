/// Configuracoes centralizadas do app
class AppConfig {
  // URL do Backend (VPS - Producao)
  static const String backendUrl = 'https://api.desenrolaai.site';

  // Supabase
  static const String supabaseUrl = 'https://ocnwpywdvefpbgvbdkxw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9jbndweXdkdmVmcGJndmJka3h3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0OTIxNjEsImV4cCI6MjA4ODA2ODE2MX0.QnBZzEjY3Kb7LXkDDbxxyozrh0ROC1cE3FrUs-FcSXc';

  // App Info
  static const String appName = 'Desenrola IA';
  static const String appVersion = '1.7.1';

  // Apple In-App Purchase Product IDs
  static const String appleMonthlyProductId = 'desenrola_ai_monthly_v2';
  static const String appleQuarterlyProductId = 'desenrola_ai_quarterly_v2';
  static const String appleYearlyProductId = 'desenrola_ai_yearly_v2';

  static const Set<String> appleProductIds = {
    appleMonthlyProductId,
    appleQuarterlyProductId,
    appleYearlyProductId,
  };
}
