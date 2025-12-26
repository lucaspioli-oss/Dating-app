import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../services/meta_pixel_service.dart';
import '../services/stripe_web_service.dart';
import '../services/checkout_web_stub.dart'
    if (dart.library.html) '../services/checkout_web_impl.dart' as checkout_web;

class EmbeddedCheckoutScreen extends StatefulWidget {
  final String? plan;
  final String? email;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;

  const EmbeddedCheckoutScreen({
    super.key,
    this.plan,
    this.email,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
  });

  @override
  State<EmbeddedCheckoutScreen> createState() => _EmbeddedCheckoutScreenState();
}

class _EmbeddedCheckoutScreenState extends State<EmbeddedCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _stripeContainerKey = GlobalKey();

  String _selectedPlan = 'quarterly';
  bool _isLoadingStripe = true;
  bool _stripeReady = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  String? _clientSecret;
  double _amount = 0;

  static const Map<String, double> prices = {
    'monthly': 29.90,
    'quarterly': 69.90,
    'yearly': 199.90,
  };

  static const Map<String, String> planNames = {
    'monthly': 'Mensal',
    'quarterly': 'Trimestral',
    'yearly': 'Anual',
  };

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
    if (widget.plan != null && prices.containsKey(widget.plan)) {
      _selectedPlan = widget.plan!;
    }
    _amount = prices[_selectedPlan] ?? 69.90;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackInitiateCheckout();
      _loadStripeElements();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    if (kIsWeb) {
      checkout_web.hideStripeContainer();
    }
    StripeWebService.destroyElements();
    super.dispose();
  }

  void _trackInitiateCheckout() {
    MetaPixelService.trackInitiateCheckout(
      value: prices[_selectedPlan] ?? 69.90,
      currency: 'BRL',
      planName: 'Desenrola IA - ${planNames[_selectedPlan]}',
      utmSource: widget.utmSource,
      utmMedium: widget.utmMedium,
      utmCampaign: widget.utmCampaign,
      utmContent: widget.utmContent,
      utmTerm: widget.utmTerm,
    );
  }

  String get _priceId {
    switch (_selectedPlan) {
      case 'monthly':
        return AppConfig.monthlyPriceId;
      case 'yearly':
        return AppConfig.yearlyPriceId;
      default:
        return AppConfig.quarterlyPriceId;
    }
  }

  void _positionStripeContainer() {
    if (!kIsWeb) return;

    final RenderBox? renderBox = _stripeContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      // Add offset for container padding (16) + header row (~36) + spacing (16) = 68
      final topOffset = position.dy + 68;
      final leftOffset = position.dx + 16; // Account for container padding
      final width = size.width - 32; // Subtract left and right padding
      checkout_web.positionStripeContainer(topOffset, leftOffset, width);
    }
  }

  Future<void> _loadStripeElements() async {
    if (_stripeReady) return;

    setState(() {
      _isLoadingStripe = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/create-embedded-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'priceId': _priceId,
          'plan': _selectedPlan,
          'email': 'pending@checkout.temp',
          'name': 'Pending',
          'utm_source': widget.utmSource,
          'utm_medium': widget.utmMedium,
          'utm_campaign': widget.utmCampaign,
          'utm_content': widget.utmContent,
          'utm_term': widget.utmTerm,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar checkout');
      }

      final data = jsonDecode(response.body);
      _clientSecret = data['clientSecret'] as String;
      _amount = (data['amount'] as num).toDouble();

      // Wait for layout to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Position the Stripe container
      _positionStripeContainer();

      final returnUrl = '${AppConfig.firebaseHostingUrl}/subscription/success';

      final success = await StripeWebService.initializeElements(
        publishableKey: AppConfig.stripePublishableKey,
        clientSecret: _clientSecret!,
        containerId: 'stripe-payment-container',
        returnUrl: returnUrl,
        amount: _amount,
      );

      if (success) {
        setState(() {
          _stripeReady = true;
          _isLoadingStripe = false;
        });
        // Reposition after state update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _positionStripeContainer();
        });
      } else {
        throw Exception('Falha ao carregar formulário de pagamento');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingStripe = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Digite um email válido');
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Digite seu nome');
      return;
    }
    if (!_stripeReady) {
      setState(() => _errorMessage = 'Aguarde o carregamento do formulário');
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
    });

    try {
      final returnUrl = '${AppConfig.firebaseHostingUrl}/subscription/success?email=${Uri.encodeComponent(email)}';

      final status = await StripeWebService.confirmPayment(returnUrl);

      if (status == 'succeeded' || status == 'processing') {
        MetaPixelService.trackPurchase(
          value: _amount,
          currency: 'BRL',
          planName: 'Desenrola IA - ${planNames[_selectedPlan]}',
          utmSource: widget.utmSource,
          utmMedium: widget.utmMedium,
          utmCampaign: widget.utmCampaign,
          utmContent: widget.utmContent,
          utmTerm: widget.utmTerm,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/subscription/success',
            arguments: {'email': email},
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo_pricing.png',
                        height: isDesktop ? 60 : 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Finalizar Assinatura',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Plan selector
                    _buildPlanSelector(),
                    const SizedBox(height: 24),

                    // Email field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'seu@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Digite seu email';
                        if (!value.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nome completo',
                      hint: 'Seu nome',
                      icon: Icons.person_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Digite seu nome';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Stripe Payment Element Container
                    Container(
                      key: _stripeContainerKey,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.credit_card, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Dados do Cartão',
                                style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Placeholder for Stripe - the actual form is positioned over this
                          SizedBox(
                            height: 200,
                            child: _isLoadingStripe
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(color: Color(0xFFE91E63)),
                                        SizedBox(height: 16),
                                        Text(
                                          'Carregando...',
                                          style: TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(), // Empty - Stripe renders over this
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pay button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_stripeReady && !_isProcessingPayment) ? _processPayment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isProcessingPayment
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Pagar R\$ ${_amount.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Security badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey[600], size: 16),
                        const SizedBox(width: 8),
                        Text('Pagamento 100% seguro via Stripe', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildPlanOption('monthly', 'Mensal', 29.90, null),
          Divider(color: Colors.grey[800], height: 1),
          _buildPlanOption('quarterly', 'Trimestral', 69.90, 'Mais popular'),
          Divider(color: Colors.grey[800], height: 1),
          _buildPlanOption('yearly', 'Anual', 199.90, 'Melhor valor'),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String id, String name, double price, String? badge) {
    final isSelected = _selectedPlan == id;
    return InkWell(
      onTap: () async {
        if (_selectedPlan != id && !_stripeReady) {
          setState(() {
            _selectedPlan = id;
            _amount = price;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFE91E63).withOpacity(0.1) : null),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFE91E63) : Colors.grey[600]!, width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE91E63))))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(name, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE91E63).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text(badge, style: const TextStyle(color: Color(0xFFE91E63), fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            Text('R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(color: isSelected ? const Color(0xFFE91E63) : Colors.grey[400], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[800]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE91E63))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
