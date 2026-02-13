import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../config/app_haptics.dart';
import '../../services/apple_iap_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/app_loading.dart';

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
  bool _isLoadingProducts = true;
  final AppleIAPService _iapService = AppleIAPService();
  StreamSubscription<PurchaseStatus>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    await _iapService.initialize();
    // If products didn't load on init, try again
    await _iapService.reloadProducts();
    _purchaseSubscription = _iapService.purchaseStatusStream.listen((status) {
      if (!mounted) return;
      switch (status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          setState(() => _isPurchasing = false);
          AppSnackBar.success(context, 'Assinatura ativada com sucesso!');
          break;
        case PurchaseStatus.error:
          setState(() => _isPurchasing = false);
          AppSnackBar.error(context, 'Erro ao processar compra. Tente novamente.');
          break;
        case PurchaseStatus.canceled:
          setState(() => _isPurchasing = false);
          break;
        case PurchaseStatus.pending:
          break;
      }
    });
    if (!mounted) return;
    setState(() => _isLoadingProducts = false);
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
      backgroundColor: AppColors.backgroundDark,
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
              // Back arrow (only if can pop)
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              if (!Navigator.canPop(context))
                const SizedBox(height: 24),
              const Text(
                'Desenrola AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Escolha seu plano',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Desbloqueie todo o potencial do Desenrola AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Pricing Cards
              if (_isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: AppLoading(message: 'Carregando planos...'),
                )
              else
                Column(
                  children: [
                    _buildPricingCard(
                      index: 0,
                      planName: 'Plano Mensal',
                      period: '/mes',
                      days: 30,
                      isPopular: false,
                      productId: AppConfig.appleMonthlyProductId,
                    ),
                    const SizedBox(height: 16),
                    _buildPricingCard(
                      index: 1,
                      planName: 'Plano Trimestral',
                      period: '/3 meses',
                      days: 90,
                      isPopular: true,
                      productId: AppConfig.appleQuarterlyProductId,
                      monthlyProductId: AppConfig.appleMonthlyProductId,
                    ),
                    const SizedBox(height: 16),
                    _buildPricingCard(
                      index: 2,
                      planName: 'Plano Anual',
                      period: '/ano',
                      days: 365,
                      isPopular: false,
                      productId: AppConfig.appleYearlyProductId,
                      monthlyProductId: AppConfig.appleMonthlyProductId,
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
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                ),
              ),

              const SizedBox(height: 12),

              // Legal text (Apple requirement)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: AppColors.textTertiary.withOpacity(0.6),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'A assinatura é renovada automaticamente até ser cancelada. '
                            'Cancele a qualquer momento nas Configurações da App Store. '
                            'O pagamento será cobrado na sua conta Apple ID ao confirmar a compra. ',
                      ),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: const TextStyle(decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(Uri.parse('https://desenrola-ia.web.app/terms')),
                      ),
                      const TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: const TextStyle(decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(Uri.parse('https://desenrola-ia.web.app/privacy')),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
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
    required String period,
    required int days,
    required bool isPopular,
    required String productId,
    String? monthlyProductId,
  }) {
    final isSelected = _selectedPlan == index;
    final iapProduct = _iapService.getProduct(productId);
    final displayPrice = iapProduct?.price ?? '';
    final rawPrice = iapProduct?.rawPrice ?? 0;
    final currencySymbol = iapProduct?.currencySymbol ?? 'R\$';

    // Calculate per-day price
    final perDayPrice = days > 0 && rawPrice > 0
        ? (rawPrice / days)
        : 0.0;
    final perDayFormatted = perDayPrice > 0
        ? '${currencySymbol} ${perDayPrice.toStringAsFixed(2).replaceAll('.', ',')}'
        : '';

    // Calculate savings vs monthly
    int savingsPercent = 0;
    if (monthlyProductId != null) {
      final monthlyProduct = _iapService.getProduct(monthlyProductId);
      if (monthlyProduct != null && monthlyProduct.rawPrice > 0 && rawPrice > 0) {
        final monthlyTotal = monthlyProduct.rawPrice * (days / 30);
        savingsPercent = ((1 - rawPrice / monthlyTotal) * 100).round();
      }
    }

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        setState(() => _selectedPlan = index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular
                ? AppColors.primary
                : (isSelected
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.elevatedDark),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
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
                    colors: [AppColors.primary, Color(0xFFFF5722)],
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: const Text(
                  'Mais Popular',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Plan name with radio + savings badge
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
                                ? AppColors.primary
                                : AppColors.textTertiary,
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
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        planName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (savingsPercent > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            'Economize $savingsPercent%',
                            style: const TextStyle(
                              color: Color(0xFF81C784),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price display
                  if (displayPrice.isNotEmpty) ...[
                    // Main price: StoreKit price + period (large)
                    Text(
                      '$displayPrice$period',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    // Per-day equivalent (small)
                    if (perDayFormatted.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'equivale a $perDayFormatted por dia',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carregando preço...',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

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
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
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
                                color: AppColors.textPrimary,
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
      AppSnackBar.error(context, 'Loja nao disponivel. Tente novamente mais tarde.');
      return;
    }

    final product = _iapService.getProduct(productId);
    if (product == null) {
      AppSnackBar.error(context, 'Produto nao encontrado. Tente novamente mais tarde.');
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      await _iapService.buySubscription(productId);
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }
}
