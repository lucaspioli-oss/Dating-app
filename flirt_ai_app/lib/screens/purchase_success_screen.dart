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
  bool _isResending = false;
  bool _emailSent = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _userEmail = widget.email;
    if (widget.sessionId != null && _userEmail == null) {
      _fetchSessionEmail();
    }
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
        });
      }
    } catch (e) {
      // Silently fail - email will be shown as null
    }
  }

  Future<void> _resendPasswordEmail() async {
    if (_userEmail == null) return;

    setState(() => _isResending = true);

    try {
      final appState = context.read<AppState>();
      final response = await http.post(
        Uri.parse('${appState.backendUrl}/resend-password-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _userEmail}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _emailSent = true;
          _isResending = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email reenviado com sucesso!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        throw Exception('Erro ao reenviar');
      }
    } catch (e) {
      setState(() => _isResending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reenviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.2),
                        const Color(0xFF4CAF50).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Pagamento Confirmado!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Bem-vindo ao Desenrola IA',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A3E)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 40,
                        color: Color(0xFFE91E63),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Defina sua senha',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enviamos um email para:',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userEmail ?? 'seu email',
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Clique no link do email para criar sua senha e acessar o app.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Resend button
                TextButton.icon(
                  onPressed: _isResending ? null : _resendPasswordEmail,
                  icon: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE91E63),
                          ),
                        )
                      : Icon(
                          _emailSent ? Icons.check : Icons.refresh,
                          size: 18,
                          color: const Color(0xFFE91E63),
                        ),
                  label: Text(
                    _emailSent ? 'Email reenviado!' : 'Reenviar email',
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade800)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Já definiu sua senha?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade800)),
                  ],
                ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ir para Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Help text
                Text(
                  'Não recebeu o email? Verifique a pasta de spam.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
