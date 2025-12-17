import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';
import '../../providers/app_state.dart';
import '../../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubscriptionRequiredScreen extends StatefulWidget {
  final SubscriptionStatus status;

  const SubscriptionRequiredScreen({
    super.key,
    required this.status,
  });

  @override
  State<SubscriptionRequiredScreen> createState() => _SubscriptionRequiredScreenState();
}

class _SubscriptionRequiredScreenState extends State<SubscriptionRequiredScreen> {
  int _selectedPlan = 1; // 0 = monthly, 1 = yearly (default - most popular)

  // Pricing configuration
  static const double monthlyPrice = 29.90;
  static const double yearlyPrice = 199.90;
  static const double monthlyOriginalPrice = 49.90; // Anchoring
  static const double yearlyOriginalPrice = 358.80; // 29.90 * 12

  // Calculate per day prices
  double get monthlyPerDay => monthlyPrice / 30;
  double get yearlyPerDay => yearlyPrice / 365;
  double get monthlyOriginalPerDay => monthlyOriginalPrice / 30;
  double get yearlyOriginalPerDay => yearlyOriginalPrice / 365;

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Escolha seu plano',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desbloqueie todo o potencial do Desenrola AI',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Monthly Plan
              _buildPlanCard(
                index: 0,
                planName: 'Plano Mensal',
                totalPrice: monthlyPrice,
                originalPrice: monthlyOriginalPrice,
                perDayPrice: monthlyPerDay,
                originalPerDayPrice: monthlyOriginalPerDay,
                period: '/mês',
                isPopular: false,
              ),
              const SizedBox(height: 16),

              // Yearly Plan (Most Popular)
              _buildPlanCard(
                index: 1,
                planName: 'Plano Anual',
                totalPrice: yearlyPrice,
                originalPrice: yearlyOriginalPrice,
                perDayPrice: yearlyPerDay,
                originalPerDayPrice: yearlyOriginalPerDay,
                period: '/ano',
                isPopular: true,
                savingsPercent: 44,
              ),
              const SizedBox(height: 32),

              // Features
              _buildFeaturesSection(),
              const SizedBox(height: 32),

              // Subscribe button
              GradientButton(
                text: 'Começar Agora',
                icon: Icons.rocket_launch,
                onPressed: () => _createStripeCheckout(context),
              ),
              const SizedBox(height: 16),

              // Guarantee
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Garantia de 7 dias',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Não gostou? Devolvemos seu dinheiro',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout button
              TextButton.icon(
                onPressed: () async {
                  await authService.signOut();
                },
                icon: Icon(Icons.logout, color: AppColors.textTertiary, size: 18),
                label: Text(
                  'Sair da conta',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String planName,
    required double totalPrice,
    required double originalPrice,
    required double perDayPrice,
    required double originalPerDayPrice,
    required String period,
    required bool isPopular,
    int? savingsPercent,
  }) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isPopular
              ? LinearGradient(
                  colors: [
                    AppColors.primaryCoral.withOpacity(0.1),
                    AppColors.primaryMagenta.withOpacity(0.1),
                  ],
                )
              : null,
          color: isPopular ? null : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? AppColors.primary
                : (isSelected ? AppColors.primary.withOpacity(0.5) : AppColors.elevatedDark),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Most Popular Badge
            if (isPopular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Text(
                  'Mais Popular',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

            // Plan content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Plan info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'R\$ ${originalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'R\$ ${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              period,
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Per day price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${originalPerDayPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'R\$ ',
                            style: TextStyle(
                              color: isPopular ? AppColors.primary : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            perDayPrice.toStringAsFixed(2).replaceAll('.', ','),
                            style: TextStyle(
                              color: isPopular ? AppColors.primary : AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'por dia',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Savings badge
            if (savingsPercent != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Economize $savingsPercent%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'O que você recebe:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureItem('Respostas ilimitadas da IA'),
          _buildFeatureItem('Todos os tons de conversa'),
          _buildFeatureItem('Análise de perfil inteligente'),
          _buildFeatureItem('Modo Expert para situações difíceis'),
          _buildFeatureItem('Suporte prioritário'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createStripeCheckout(BuildContext context) async {
    try {
      final authService = FirebaseAuthService();
      final user = authService.currentUser;
      final appState = Provider.of<AppState>(context, listen: false);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Erro: Usuário não autenticado'),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Preparando checkout...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      // Get backend URL
      final backendUrl = appState.backendUrl;

      // Determine price ID and plan based on selection
      final priceId = _selectedPlan == 0
          ? AppConfig.monthlyPriceId
          : AppConfig.yearlyPriceId;
      final plan = _selectedPlan == 0 ? 'monthly' : 'yearly';

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
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Erro ao criar checkout: ${response.body}')),
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
