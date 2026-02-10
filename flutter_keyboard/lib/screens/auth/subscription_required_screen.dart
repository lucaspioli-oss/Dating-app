import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../services/apple_iap_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';

class SubscriptionRequiredScreen extends StatefulWidget {
  final SubscriptionStatus status;

  const SubscriptionRequiredScreen({
    super.key,
    required this.status,
  });

  @override
  State<SubscriptionRequiredScreen> createState() =>
      _SubscriptionRequiredScreenState();
}

class _SubscriptionRequiredScreenState
    extends State<SubscriptionRequiredScreen> {
  int _selectedPlan = 1; // 0 = monthly, 1 = quarterly, 2 = yearly
  bool _isPurchasing = false;
  final AppleIAPService _iapService = AppleIAPService();
  StreamSubscription<PurchaseStatus>? _purchaseSubscription;

  static const double monthlyPrice = 29.90;
  static const double quarterlyPrice = 69.90;
  static const double yearlyPrice = 199.90;

  double get monthlyPerDay => monthlyPrice / 30;
  double get quarterlyPerDay => quarterlyPrice / 90;
  double get yearlyPerDay => yearlyPrice / 365;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    await _iapService.initialize();
    _purchaseSubscription = _iapService.purchaseStatusStream.listen((status) {
      if (!mounted) return;
      switch (status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          setState(() => _isPurchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assinatura ativada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case PurchaseStatus.error:
          setState(() => _isPurchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao processar compra. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case PurchaseStatus.canceled:
          setState(() => _isPurchasing = false);
          break;
        case PurchaseStatus.pending:
          break;
      }
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 0,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Desenrola AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Escolha seu plano',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Desbloqueie todo o potencial do Desenrola AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Pricing Cards
              Column(
                children: [
                  _buildPricingCard(
                    index: 0,
                    planName: 'Plano Mensal',
                    pricePerDay: monthlyPerDay,
                    totalPrice: monthlyPrice,
                    period: '/mes',
                    isPopular: false,
                    productId: AppConfig.appleMonthlyProductId,
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
                    productId: AppConfig.appleQuarterlyProductId,
                  ),
                  const SizedBox(height: 16),
                  _buildPricingCard(
                    index: 2,
                    planName: 'Plano Anual',
                    pricePerDay: yearlyPerDay,
                    totalPrice: yearlyPrice,
                    period: '/ano',
                    isPopular: false,
                    productId: AppConfig.appleYearlyProductId,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Restore purchases
              TextButton(
                onPressed: _isPurchasing
                    ? null
                    : () async {
                        setState(() => _isPurchasing = true);
                        await _iapService.restorePurchases();
                        await Future.delayed(const Duration(seconds: 3));
                        if (mounted) setState(() => _isPurchasing = false);
                      },
                child: Text(
                  'Restaurar compras',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),

              const SizedBox(height: 8),

              // Logout button
              TextButton.icon(
                onPressed: () async {
                  await authService.signOut();
                },
                icon:
                    Icon(Icons.logout, color: AppColors.textTertiary, size: 18),
                label: Text(
                  'Sair da conta',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 16),
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
    required String productId,
    int? savingsPercent,
  }) {
    final isSelected = _selectedPlan == index;
    final iapProduct = _iapService.getProduct(productId);
    final displayPrice = iapProduct?.price ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular
                ? const Color(0xFFE91E63)
                : (isSelected
                    ? const Color(0xFFE91E63).withOpacity(0.5)
                    : const Color(0xFF2A2A3E)),
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
            if (isPopular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(18)),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Plan name with radio and savings badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE91E63)
                                : Colors.grey,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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

                  // Price from App Store
                  if (displayPrice.isNotEmpty) ...[
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      period,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    Text(
                      planName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPurchasing
                          ? null
                          : () {
                              setState(() => _selectedPlan = index);
                              _purchase(productId);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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

  Future<void> _purchase(String productId) async {
    if (!_iapService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loja nao disponivel. Tente novamente mais tarde.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final product = _iapService.getProduct(productId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto nao encontrado. Tente novamente mais tarde.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      await _iapService.buySubscription(productId);
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
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
