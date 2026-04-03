import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class SyncScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SyncScreen({super.key, required this.onComplete});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _phoneController = TextEditingController();
  String? _pairingCode;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _connectedNumber;
  Timer? _pollTimer;
  String? _errorMessage;

  String get _baseUrl => 'https://api.desenrolaai.site';

  String? get _authToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingConnection() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/sync/instance/status'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['live_state'] == 'open' && mounted) {
          setState(() {
            _isConnected = true;
            _connectedNumber = data['connected_number'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _requestPairingCode() async {
    var phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty || phone.length < 10) {
      _showError('Informe seu numero com DDD');
      return;
    }
    if (!phone.startsWith('55')) phone = '55$phone';

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _pairingCode = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sync/instance/pair'),
        headers: _headers,
        body: jsonEncode({'phoneNumber': phone}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 409) {
        setState(() {
          _isConnected = true;
          _connectedNumber = data['connected_number'];
          _isConnecting = false;
        });
        return;
      }

      if (data['pairing_code'] != null) {
        setState(() {
          _pairingCode = data['pairing_code'];
          _isConnecting = false;
        });
        _startPolling();
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Erro ao gerar codigo. Tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Erro de conexao. Verifique sua internet.';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await http.get(
          Uri.parse('$_baseUrl/sync/instance/status'),
          headers: _headers,
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['live_state'] == 'open' || data['evo_status'] == 'connected') {
            _pollTimer?.cancel();
            if (mounted) {
              setState(() {
                _isConnected = true;
                _connectedNumber = data['connected_number'];
              });
            }
          }
        }
      } catch (_) {}
    });

    // Timeout 3 min
    Future.delayed(const Duration(minutes: 3), () {
      if (!_isConnected && mounted) {
        _pollTimer?.cancel();
        setState(() {
          _pairingCode = null;
          _errorMessage = 'Tempo esgotado. Tente novamente.';
        });
      }
    });
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedSync', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isConnected ? _buildConnected() : _buildConnect(),
          ),
        ),
      ),
    );
  }

  Widget _buildConnect() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'Sincronizar Conversas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Receba sugestoes automaticas\nem tempo real nas suas conversas.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  if (_pairingCode != null) ...[
                    // Show pairing code
                    _buildPairingCodeView(),
                  ] else ...[
                    // Phone input
                    _buildPhoneInput(),
                  ],

                  const Spacer(),

                  // Error
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextButton(
                    onPressed: _complete,
                    child: const Text(
                      'Configurar depois',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sync, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 28),
        const Text(
          'Informe o numero do seu WhatsApp',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '11 99999-9999',
            hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5), fontSize: 18),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('+55', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 56),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Gerar codigo',
            isLoading: _isConnecting,
            onPressed: _isConnecting ? null : _requestPairingCode,
          ),
        ),
      ],
    );
  }

  Widget _buildPairingCodeView() {
    // Format code with dash: ABCD-EFGH
    final code = _pairingCode!;
    final formatted = code.length >= 8
        ? '${code.substring(0, 4)}-${code.substring(4)}'
        : code;

    return Column(
      children: [
        const Text(
          'Seu codigo de vinculacao:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Codigo copiado!'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatted,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.copy, color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep('1', 'Abra o WhatsApp'),
              const SizedBox(height: 10),
              _buildStep('2', 'Toque em Configuracoes > Dispositivos conectados'),
              const SizedBox(height: 10),
              _buildStep('3', 'Toque em Conectar dispositivo'),
              const SizedBox(height: 10),
              _buildStep('4', 'Toque em "Vincular com numero de telefone"'),
              const SizedBox(height: 10),
              _buildStep('5', 'Digite o codigo acima'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Aguardando vinculacao...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _pollTimer?.cancel();
            setState(() {
              _pairingCode = null;
              _errorMessage = null;
            });
          },
          child: const Text('Tentar novamente', style: TextStyle(color: AppColors.textTertiary)),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildConnected() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2),
          ),
          child: const Icon(Icons.check, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Conectado!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (_connectedNumber != null) ...[
          const SizedBox(height: 6),
          Text(
            '+$_connectedNumber',
            style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Agora e so adicionar os contatos\nque voce quer conversar no app.\n\nSuas sugestoes serao geradas\nautomaticamente em tempo real.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Comecar',
            onPressed: _complete,
          ),
        ),
      ],
    );
  }
}
