import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../services/error_reporter.dart';
import '../config/app_theme.dart';

class SupportDialog {
  static Future<void> show(BuildContext context, {required String page}) async {
    final controller = TextEditingController();
    final emailController = TextEditingController();
    final session = Supabase.instance.client.auth.currentSession;
    final hasSession = session != null;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Fale com o suporte',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasSession) ...[
              TextField(
                controller: emailController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Seu email',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.elevatedDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.elevatedDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Descreva o problema ou duvida...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.elevatedDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.elevatedDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;

              final email = hasSession
                  ? session.user.email
                  : emailController.text.trim();

              try {
                await http.post(
                  Uri.parse('${AppConfig.backendUrl}/support/message'),
                  headers: {
                    'Content-Type': 'application/json',
                    if (hasSession) 'Authorization': 'Bearer ${session.accessToken}',
                  },
                  body: json.encode({
                    'email': email,
                    'message': message,
                    'page': page,
                  }),
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppSnackBar.success(context, 'Mensagem enviada! Responderemos em breve.');
                }
              } catch (e) {
                ErrorReporter.instance.report(message: e.toString(), context: 'support.sendMessage');
                if (ctx.mounted) {
                  AppSnackBar.error(context, 'Erro ao enviar. Tente novamente.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
