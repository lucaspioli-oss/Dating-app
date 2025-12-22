import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';

class PurchaseSuccessScreen extends StatefulWidget {
  final String? sessionId;
  final String? email;

  const PurchaseSuccessScreen({
    super.key,
    this.sessionId,
    this.email,
  });

  @override
  State<PurchaseSuccessScreen> createState() => _PurchaseSuccessScreenState();
}

class _PurchaseSuccessScreenState extends State<PurchaseSuccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _userEmail;
  bool _isLoadingEmail = true;

  @override
  void initState() {
    super.initState();
    _userEmail = widget.email;
    if (widget.sessionId != null && _userEmail == null) {
      _fetchSessionEmail();
    } else {
      _isLoadingEmail = false;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessionEmail() async {
    try {
      final appState = context.read<AppState>();
      final response = await http.get(
        Uri.parse('${appState.backendUrl}/checkout-session/${widget.sessionId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userEmail = data['email'];
          _isLoadingEmail = false;
        });
      } else {
        setState(() => _isLoadingEmail = false);
      }
    } catch (e) {
      setState(() => _isLoadingEmail = false);
    }
  }

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppState>();
      final response = await http.post(
        Uri.parse('${appState.backendUrl}/set-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Conta criada com sucesso!'),
                ],
              ),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar conta');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    if (_isLoadingEmail) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
      );
    }

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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Seu assistente inteligente de conversas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: isDesktop ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 40 : 32),

                    // Success badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pagamento confirmado!',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 32 : 24),

                    // Welcome text
                    Text(
                      'Bem-vindo ao Desenrola AI!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 28 : 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure sua senha para acessar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email field (read-only)
                    _buildTextField(
                      controller: TextEditingController(text: _userEmail ?? ''),
                      label: 'Email',
                      hint: 'seu@email.com',
                      icon: Icons.email_outlined,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Senha',
                      hint: 'Crie sua senha',
                      icon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite sua senha';
                        }
                        if (value.length < 6) {
                          return 'Senha deve ter no mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Senha',
                      hint: 'Digite novamente',
                      icon: Icons.lock_outlined,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme sua senha';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Create account button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE91E63).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Criar minha conta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Already have account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Já tem uma conta?',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                },
                          child: const Text(
                            'Fazer login',
                            style: TextStyle(
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    bool obscureText = false,
    bool readOnly = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey[500],
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? const Color(0xFF1A1A2E) : const Color(0xFF1A1A2E).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE91E63)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
