import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
  String? _qrBase64;
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

  Future<void> _startConnect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _qrBase64 = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sync/instance/create'),
        headers: _headers,
        body: jsonEncode({}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 409 && data['error'] == 'Already connected') {
        setState(() {
          _isConnected = true;
          _connectedNumber = data['connected_number'];
          _isConnecting = false;
        });
        return;
      }

      if (data['qrcode']?['base64'] != null) {
        setState(() {
          _qrBase64 = data['qrcode']['base64'];
          _isConnecting = false;
        });
      } else {
        setState(() => _isConnecting = false);
      }

      _startPolling();
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Erro ao conectar. Tente novamente.';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final statusRes = await http.get(
          Uri.parse('$_baseUrl/sync/instance/status'),
          headers: _headers,
        );
        if (statusRes.statusCode == 200) {
          final data = jsonDecode(statusRes.body);
          if (data['live_state'] == 'open' || data['evo_status'] == 'connected') {
            _pollTimer?.cancel();
            if (mounted) {
              setState(() {
                _isConnected = true;
                _connectedNumber = data['connected_number'];
              });
            }
            return;
          }
        }

        // Refresh QR
        final qrRes = await http.get(
          Uri.parse('$_baseUrl/sync/instance/qr'),
          headers: _headers,
        );
        if (qrRes.statusCode == 200) {
          final data = jsonDecode(qrRes.body);
          if (data['connected'] == true) {
            _pollTimer?.cancel();
            if (mounted) {
              setState(() {
                _isConnected = true;
                _connectedNumber = data['number'];
              });
            }
          } else if (data['base64'] != null && mounted) {
            setState(() => _qrBase64 = data['base64']);
          }
        }
      } catch (_) {}
    });

    Future.delayed(const Duration(minutes: 2), () {
      if (!_isConnected && mounted) {
        _pollTimer?.cancel();
        setState(() => _errorMessage = 'Tempo esgotado. Tente novamente.');
      }
    });
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedSync', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isConnected ? _buildConnected() : _buildConnect(),
        ),
      ),
    );
  }

  // ── Connect screen (QR code) ──

  Widget _buildConnect() {
    return Column(
      children: [
        const SizedBox(height: 40),
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
          'Escaneie o codigo para sincronizar suas\nconversas e receber sugestoes em tempo real.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // QR area
        Expanded(
          child: Center(
            child: _isConnecting
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Gerando codigo...', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  )
                : _qrBase64 != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.memory(
                              base64Decode(_qrBase64!.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '')),
                              width: 240,
                              height: 240,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Abra seu app de mensagens >\nDispositivos conectados > Conectar',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sync, color: AppColors.primary, size: 48),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Conecte para receber sugestoes\nautomaticas durante suas conversas.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
          ),
        ),

        // Error
        if (_errorMessage != null) ...[
          Container(
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

        // Buttons
        if (_qrBase64 == null && !_isConnecting)
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: 'Conectar',
              icon: Icons.qr_code_scanner,
              onPressed: _startConnect,
            ),
          ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _complete,
          child: const Text(
            'Configurar depois',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Connected screen ──

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
