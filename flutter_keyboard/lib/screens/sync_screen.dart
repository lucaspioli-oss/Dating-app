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
  // Steps: 0 = add contacts, 1 = QR code, 2 = connected
  int _step = 0;

  // Contacts
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  bool _isAddingContact = false;

  // QR
  String? _qrBase64;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _connectedNumber;
  Timer? _pollTimer;
  String? _errorMessage;

  String get _baseUrl {
    return 'https://api.desenrolaai.site';
  }

  String? get _authToken {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _checkExistingConnection();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/sync/contacts'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _contacts = data
                .where((c) => c['provider'] == 'whatsapp' && c['is_active'] == true)
                .map<Map<String, dynamic>>((c) => {
                      'id': c['id'],
                      'name': c['display_name'] ?? '',
                      'phone': (c['phone_number'] ?? c['external_id'] ?? '')
                          .toString()
                          .replaceAll(RegExp(r'@s\.whatsapp\.net$'), ''),
                    })
                .toList();
          });
        }
      }
    } catch (_) {}
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
            _step = 2;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    var phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    if (phone.isEmpty || phone.length < 10) {
      _showError('Informe um telefone valido (DDDnumero)');
      return;
    }

    if (!phone.startsWith('55')) phone = '55$phone';

    if (_contacts.any((c) => c['phone'] == phone)) {
      _showError('Contato ja adicionado');
      return;
    }

    setState(() => _isAddingContact = true);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sync/contacts'),
        headers: _headers,
        body: jsonEncode({
          'external_id': '$phone@s.whatsapp.net',
          'provider': 'whatsapp',
          'display_name': name.isEmpty ? phone : name,
          'phone_number': phone,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final saved = jsonDecode(res.body);
        setState(() {
          _contacts.add({
            'id': saved['id'],
            'name': name.isEmpty ? phone : name,
            'phone': phone,
          });
          _nameController.clear();
          _phoneController.clear();
          _errorMessage = null;
        });
      } else {
        _showError('Erro ao adicionar contato');
      }
    } catch (_) {
      _showError('Erro de conexao');
    } finally {
      if (mounted) setState(() => _isAddingContact = false);
    }
  }

  Future<void> _removeContact(int index) async {
    final contact = _contacts[index];
    if (contact['id'] != null) {
      try {
        await http.delete(
          Uri.parse('$_baseUrl/sync/contacts/${contact['id']}'),
          headers: _headers,
        );
      } catch (_) {}
    }
    setState(() => _contacts.removeAt(index));
  }

  Future<void> _startConnect() async {
    if (_contacts.isEmpty) {
      _showError('Adicione pelo menos 1 contato');
      return;
    }

    setState(() {
      _step = 1;
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
          _step = 2;
          _isConnecting = false;
        });
        return;
      }

      if (data['qrcode']?['base64'] != null) {
        setState(() {
          _qrBase64 = data['qrcode']['base64'];
          _isConnecting = false;
        });
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
        // Check status
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
                _step = 2;
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
                _step = 2;
              });
            }
          } else if (data['base64'] != null && mounted) {
            setState(() => _qrBase64 = data['base64']);
          }
        }
      } catch (_) {}
    });

    // Timeout after 2 min
    Future.delayed(const Duration(minutes: 2), () {
      if (!_isConnected && mounted) {
        _pollTimer?.cancel();
        setState(() => _errorMessage = 'Tempo esgotado. Tente novamente.');
      }
    });
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Steps indicator
              _buildSteps(),
              const SizedBox(height: 24),
              // Content
              Expanded(
                child: _step == 0
                    ? _buildContactsStep()
                    : _step == 1
                        ? _buildQRStep()
                        : _buildConnectedStep(),
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
              // Skip button
              if (_step != 2)
                TextButton(
                  onPressed: widget.onComplete,
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
  }

  Widget _buildSteps() {
    return Row(
      children: [
        _buildStepIndicator(0, 'Contatos'),
        const SizedBox(width: 8),
        _buildStepIndicator(1, 'Sincronizar'),
        const SizedBox(width: 8),
        _buildStepIndicator(2, 'Pronto'),
      ],
    );
  }

  Widget _buildStepIndicator(int index, String label) {
    final isActive = _step == index;
    final isDone = _step > index;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.success.withOpacity(0.1)
              : isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone
                ? AppColors.success.withOpacity(0.3)
                : isActive
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.elevatedDark,
          ),
        ),
        child: Column(
          children: [
            Text(
              isDone ? '\u2713' : '${index + 1}',
              style: TextStyle(
                color: isDone
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : AppColors.textTertiary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDone
                    ? AppColors.success
                    : isActive
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Contacts ──

  Widget _buildContactsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sincronizar Conversas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adicione os contatos que deseja monitorar.\nSuas sugestoes serao geradas em tempo real.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Input row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Nome',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'DDD + Numero',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isAddingContact ? null : _addContact,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isAddingContact
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Contact list
        Expanded(
          child: _contacts.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum contato adicionado.\nAdicione pelo menos 1 pra continuar.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final c = _contacts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.elevatedDark),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name'] ?? '',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '+${c['phone']}',
                                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                            onPressed: () => _removeContact(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 12),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Gerar codigo de sincronizacao',
            onPressed: _contacts.isNotEmpty ? _startConnect : null,
          ),
        ),
      ],
    );
  }

  // ── Step 1: QR Code ──

  Widget _buildQRStep() {
    return Column(
      children: [
        const Text(
          'Sincronizar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Escaneie o codigo com seu app de mensagens\npara sincronizar suas conversas.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        if (_isConnecting)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Gerando codigo...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else if (_qrBase64 != null) ...[
          Expanded(
            child: Center(
              child: Container(
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
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Abra seu app de mensagens > Dispositivos\nconectados > Conectar aparelho',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ] else
          const Expanded(
            child: Center(
              child: Text(
                'Erro ao gerar codigo.\nTente novamente.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _pollTimer?.cancel();
              setState(() {
                _step = 0;
                _qrBase64 = null;
                _isConnecting = false;
              });
            },
            child: const Text('Voltar'),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Connected ──

  Widget _buildConnectedStep() {
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
          'Conversas Sincronizadas!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_connectedNumber != null)
          Text(
            '+$_connectedNumber',
            style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 12),
        const Text(
          'Suas sugestoes serao geradas automaticamente\nquando receber mensagens.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Contact summary
        if (_contacts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: _contacts
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.elevatedDark),
                      ),
                      child: Text(
                        c['name'] ?? c['phone'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Comecar',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasCompletedSync', true);
              widget.onComplete();
            },
          ),
        ),
      ],
    );
  }
}
