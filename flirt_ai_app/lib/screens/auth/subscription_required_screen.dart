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

    // Breakpoints responsivos
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;
    final isMobile = screenWidth <= 600;

    // Tamanhos responsivos do logo
    double logoHeight;
    if (isDesktop) {
      logoHeight = 120;
    } else if (isTablet) {
      logoHeight = 90;
    } else {
      logoHeight = 70;
    }

    // Tamanhos responsivos de fonte do título
    double titleFontSize;
    if (isDesktop) {
      titleFontSize = 36;
    } else if (isTablet) {
      titleFontSize = 28;
    } else {
      titleFontSize = 22;
    }

    // Padding horizontal responsivo
    double horizontalPadding;
    if (isDesktop) {
      horizontalPadding = 64;
    } else if (isTablet) {
      horizontalPadding = 40;
    } else {
      horizontalPadding = 20;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 16 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: isDesktop ? 60 : (isTablet ? 40 : 20)),

              // Logo - Desenrola AI (responsivo)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 400 : (isTablet ? 300 : 250),
                  ),
                  child: Image.asset(
                    'assets/images/logo_pricing.png',
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 40 : 28)),

              // Title
              Text(
                'Escolha seu plano',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: titleFontSize,
                ),
              ),
              SizedBox(height: isDesktop ? 16 : 10),
              Text(
                'Desbloqueie todo o potencial do Desenrola AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                ),
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 40 : 28)),

              // Pricing Cards - Layout responsivo
              if (isDesktop || isTablet)
                // Layout horizontal para desktop e tablet
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
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 24 : 16),
                    Flexible(
                      child: _buildPricingCard(
                        index: 1,
                        planName: 'Plano Trimestral',
                        pricePerDay: quarterlyPerDay,
                        totalPrice: quarterlyPrice,
                        period: '/3 meses',
                        isPopular: true,
                        savingsPercent: 22,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 24 : 16),
                    Flexible(
                      child: _buildPricingCard(
                        index: 2,
                        planName: 'Plano Anual',
                        pricePerDay: yearlyPerDay,
                        totalPrice: yearlyPrice,
                        period: '/ano',
                        isPopular: false,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                )
              else
                // Layout vertical para mobile
                Column(
                  children: [
                    _buildPricingCard(
                      index: 0,
                      planName: 'Plano Mensal',
                      pricePerDay: monthlyPerDay,
                      totalPrice: monthlyPrice,
                      period: '/mês',
                      isPopular: false,
                      isDesktop: false,
                      isTablet: false,
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
                      isDesktop: false,
                      isTablet: false,
                    ),
                    const SizedBox(height: 16),
                    _buildPricingCard(
                      index: 2,
                      planName: 'Plano Anual',
                      pricePerDay: yearlyPerDay,
                      totalPrice: yearlyPrice,
                      period: '/ano',
                      isPopular: false,
                      isDesktop: false,
                      isTablet: false,
                    ),
                  ],
                ),

              SizedBox(height: isDesktop ? 60 : 40),

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
              SizedBox(height: isDesktop ? 60 : 40),
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
    required bool isDesktop,
    required bool isTablet,
    int? savingsPercent,
  }) {
    final isSelected = _selectedPlan == index;

    // Tamanhos responsivos do card
    double cardMaxWidth;
    double cardPadding;
    double priceFontSize;
    double buttonPadding;

    if (isDesktop) {
      cardMaxWidth = 340;
      cardPadding = 28;
      priceFontSize = 56;
      buttonPadding = 16;
    } else if (isTablet) {
      cardMaxWidth = 280;
      cardPadding = 20;
      priceFontSize = 44;
      buttonPadding = 14;
    } else {
      cardMaxWidth = double.infinity;
      cardPadding = 20;
      priceFontSize = 42;
      buttonPadding = 14;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        constraints: BoxConstraints(maxWidth: cardMaxWidth),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular
                ? const Color(0xFFE91E63)
                : (isSelected ? const Color(0xFFE91E63).withOpacity(0.5) : const Color(0xFF2A2A3E)),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Most Popular Badge
            if (isPopular)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Text(
                  'Mais Popular',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 15 : 14,
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                children: [
                  // Plan name with radio and savings badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Radio button
                      Container(
                        width: isDesktop ? 24 : 20,
                        height: isDesktop ? 24 : 20,
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
                                  width: isDesktop ? 12 : 10,
                                  height: isDesktop ? 12 : 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: isDesktop ? 12 : 10),
                      Text(
                        planName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isDesktop ? 18 : 16,
                        ),
                      ),
                      if (savingsPercent != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 10 : 8,
                            vertical: isDesktop ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Economize $savingsPercent%',
                            style: TextStyle(
                              color: const Color(0xFF4CAF50),
                              fontSize: isDesktop ? 12 : 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isDesktop ? 28 : 24),

                  // Price per day - main highlight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: isDesktop ? 10 : 8),
                        child: Text(
                          'R\$ ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        pricePerDay.toStringAsFixed(2).replaceAll('.', ','),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: priceFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: isDesktop ? 10 : 8),
                        child: Text(
                          ' por dia',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isDesktop ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),

                  // Total price
                  Text(
                    'R\$ ${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}$period',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 28 : 24),

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
                        padding: EdgeInsets.symmetric(vertical: buttonPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Assinar Agora',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 16 : 15,
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
