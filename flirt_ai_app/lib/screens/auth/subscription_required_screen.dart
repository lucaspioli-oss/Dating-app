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
  int _selectedPlan = 1; // 0 = monthly, 1 = quarterly (default), 2 = yearly

  // Pricing configuration
  static const double monthlyPrice = 29.90;
  static const double quarterlyPrice = 69.90;
  static const double yearlyPrice = 199.90;

  // Calculate per day prices
  double get monthlyPerDay => monthlyPrice / 30; // ~1.00
  double get quarterlyPerDay => quarterlyPrice / 90; // ~0.78
  double get yearlyPerDay => yearlyPrice / 365; // ~0.55

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 48 : 20,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: isWideScreen ? 40 : 24),

              // Logo - Desenrola AI
              Center(
                child: Image.asset(
                  'assets/images/logo_pricing.png',
                  height: isWideScreen ? 80 : 60,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: isWideScreen ? 48 : 32),

              // Title
              Text(
                'Escolha seu plano',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isWideScreen ? 32 : 24,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Desbloqueie todo o potencial do Desenrola AI',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                      fontSize: isWideScreen ? 16 : 14,
                    ),
              ),
              SizedBox(height: isWideScreen ? 48 : 32),

              // Pricing Cards - Horizontal layout for web, vertical for mobile
              if (isWideScreen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: _buildPricingCard(
                        index: 0,
                        planName: 'Plano Mensal',
                        pricePerDay: monthlyPerDay,
                        totalPrice: monthlyPrice,
                        period: '/mês',
                        isPopular: false,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: _buildPricingCard(
                        index: 1,
                        planName: 'Plano Trimestral',
                        pricePerDay: quarterlyPerDay,
                        totalPrice: quarterlyPrice,
                        period: '/3 meses',
                        isPopular: true,
                        savingsPercent: 22,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: _buildPricingCard(
                        index: 2,
                        planName: 'Plano Anual',
                        pricePerDay: yearlyPerDay,
                        totalPrice: yearlyPrice,
                        period: '/ano',
                        isPopular: false,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildPricingCard(
                      index: 0,
                      planName: 'Plano Mensal',
                      pricePerDay: monthlyPerDay,
                      totalPrice: monthlyPrice,
                      period: '/mês',
                      isPopular: false,
                    ),
                    const SizedBox(height: 16),
                    _buildPricingCard(
                      index: 1,
                      planName: 'Plano Trimestral',
                      pricePerDay: quarterlyPerDay,
                      totalPrice: quarterlyPrice,
                      period: '/3 meses',
                      isPopular: true,
                      savingsPercent: 22,
                    ),
                    const SizedBox(height: 16),
                    _buildPricingCard(
                      index: 2,
                      planName: 'Plano Anual',
                      pricePerDay: yearlyPerDay,
                      totalPrice: yearlyPrice,
                      period: '/ano',
                      isPopular: false,
                    ),
                  ],
                ),

              const SizedBox(height: 40),

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

  Widget _buildPricingCard({
    required int index,
    required String planName,
    required double pricePerDay,
    required double totalPrice,
    required String period,
    required bool isPopular,
    int? savingsPercent,
  }) {
    final isSelected = _selectedPlan == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    final cardWidth = isWideScreen ? 280.0 : double.infinity;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        width: cardWidth,
        constraints: BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular
                ? const Color(0xFFE91E63)
                : (isSelected ? const Color(0xFFE91E63).withOpacity(0.5) : const Color(0xFF2A2A3E)),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Most Popular Badge
            if (isPopular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
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

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Plan name with radio and savings badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Radio button
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        planName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (savingsPercent != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Economize $savingsPercent%',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price per day - main highlight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'R\$ ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        pricePerDay.toStringAsFixed(2).replaceAll('.', ','),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          ' por dia',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Total price
                  Text(
                    'R\$ ${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}$period',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedPlan = index);
                        _createStripeCheckout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Assinar Agora',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFE91E63)),
                SizedBox(height: 16),
                Text(
                  'Preparando checkout...',
                  style: TextStyle(color: Colors.white),
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
      late final String priceId;
      late final String plan;

      switch (_selectedPlan) {
        case 0:
          priceId = AppConfig.monthlyPriceId;
          plan = 'monthly';
          break;
        case 1:
          priceId = AppConfig.quarterlyPriceId;
          plan = 'quarterly';
          break;
        case 2:
          priceId = AppConfig.yearlyPriceId;
          plan = 'yearly';
          break;
        default:
          priceId = AppConfig.quarterlyPriceId;
          plan = 'quarterly';
      }

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
