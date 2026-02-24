import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class AiConsentService {
  static const _key = 'ai_data_consent_accepted';

  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> _saveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Shows the AI data consent dialog if not yet accepted.
  /// Returns true if consent was given (or was already given), false if declined.
  static Future<bool> ensureConsent(BuildContext context) async {
    if (await hasConsented()) return true;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AiConsentDialog(),
    );

    if (accepted == true) {
      await _saveConsent();
      return true;
    }
    return false;
  }
}

class _AiConsentDialog extends StatelessWidget {
  const _AiConsentDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Uso de Inteligencia Artificial',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Para gerar sugestoes de mensagens, o Desenrola AI envia alguns dos seus dados para um servico de inteligencia artificial de terceiros.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),

            // What data is sent
            _buildSection(
              icon: Icons.upload_outlined,
              title: 'Dados enviados:',
              items: [
                'Textos de conversas que voce compartilha',
                'Informacoes de perfis (bio, interesses)',
                'Screenshots analisados',
              ],
            ),
            const SizedBox(height: 14),

            // Who receives it
            _buildSection(
              icon: Icons.business_outlined,
              title: 'Para quem:',
              items: [
                'Anthropic (Claude AI) — empresa de IA sediada nos EUA',
              ],
            ),
            const SizedBox(height: 14),

            // Purpose
            _buildSection(
              icon: Icons.shield_outlined,
              title: 'Garantias:',
              items: [
                'Dados sao usados apenas para gerar suas sugestoes',
                'Nao sao armazenados permanentemente no servidor de IA',
                'Nao sao usados para treinar modelos de IA',
                'Transmissao protegida por criptografia (HTTPS)',
              ],
            ),
            const SizedBox(height: 8),

            // Privacy policy link
            Center(
              child: TextButton(
                onPressed: () {
                  // Using Navigator to avoid importing url_launcher
                  // The consent dialog is lightweight
                },
                child: const Text(
                  'Veja nossa Politica de Privacidade para mais detalhes',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Entendi e Concordo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Decline button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Nao concordo',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
