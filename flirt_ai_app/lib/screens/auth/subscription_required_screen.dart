import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';
import '../../providers/app_state.dart';
import '../../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubscriptionRequiredScreen extends StatelessWidget {
  final SubscriptionStatus status;

  const SubscriptionRequiredScreen({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    String title;
    String message;
    IconData icon;
    Color color;

    switch (status) {
      case SubscriptionStatus.expired:
        title = 'Assinatura Expirada';
        message =
            'Sua assinatura expirou. Renove para continuar usando o Flirt AI.';
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case SubscriptionStatus.cancelled:
        title = 'Assinatura Cancelada';
        message =
            'Sua assinatura foi cancelada. Assine novamente para continuar.';
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        title = 'Assinatura Necessária';
        message =
            'Você precisa de uma assinatura ativa para usar o Flirt AI.';
        icon = Icons.lock_outlined;
        color = Colors.grey;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                icon,
                size: 100,
                color: color,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 48),

              // Pricing plans
              _buildPricingCard(
                context,
                title: 'Plano Mensal',
                price: 'R\$ ${AppConfig.monthlyPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                period: '/mês',
                features: [
                  'Conversas ilimitadas',
                  'Todos os tons de IA',
                  'Modo Expert completo',
                  'Análise de perfil com IA',
                  'Suporte prioritário',
                ],
                stripePriceId: AppConfig.monthlyPriceId,
                plan: 'monthly',
              ),
              const SizedBox(height: 16),
              _buildPricingCard(
                context,
                title: 'Plano Anual',
                price: 'R\$ ${AppConfig.yearlyPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                period: '/ano',
                badge: '45% OFF',
                features: [
                  'Tudo do plano mensal',
                  '2 meses grátis',
                  'Economia de R\$ 158,90',
                ],
                stripePriceId: AppConfig.yearlyPriceId,
                plan: 'yearly',
                isHighlighted: true,
              ),
              const SizedBox(height: 32),

              // Logout button
              OutlinedButton(
                onPressed: () async {
                  await authService.signOut();
                },
                child: const Text('Sair da Conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    String? badge,
    required List<String> features,
    required String stripePriceId,
    required String plan,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isHighlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                period,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _createStripeCheckout(context, stripePriceId, plan),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Assinar Agora'),
          ),
        ],
      ),
    );
  }

  Future<void> _createStripeCheckout(
    BuildContext context,
    String priceId,
    String plan,
  ) async {
    try {
      final authService = FirebaseAuthService();
      final user = authService.currentUser;
      final appState = Provider.of<AppState>(context, listen: false);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Usuário não autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      // Get backend URL from app state (configured in settings)
      final backendUrl = appState.backendUrl;

      final response = await http.post(
        Uri.parse('$backendUrl/create-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'priceId': priceId,
          'plan': plan,
        }),
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutUrl = data['url'] as String;

        // Open Stripe Checkout in browser
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar checkout: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
