import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';
import '../config/app_theme.dart';

/// Screen opened via deep link from keyboard extension.
/// Grabs the latest photo, analyzes it, shows suggestions.
/// User taps a suggestion → saved to shared storage → returns to previous app.
class ScreenshotAnalyzeScreen extends StatefulWidget {
  const ScreenshotAnalyzeScreen({super.key});

  @override
  State<ScreenshotAnalyzeScreen> createState() => _ScreenshotAnalyzeScreenState();
}

class _ScreenshotAnalyzeScreenState extends State<ScreenshotAnalyzeScreen> {
  static const _nativeChannel = MethodChannel('com.desenrolaai/native');

  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  bool _isLoadingImage = true;
  List<String> _suggestions = [];
  String? _error;
  String? _profileName;

  @override
  void initState() {
    super.initState();
    _loadProfileContext();
    _grabLatestPhoto();
  }

  void _loadProfileContext() {
    // Read selected profile from shared UserDefaults (set by keyboard)
    try {
      _nativeChannel.invokeMethod('getSharedDefault', {'key': 'kb_pendingProfileName'}).then((value) {
        if (value != null && mounted) {
          setState(() => _profileName = value as String);
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  Future<void> _grabLatestPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        // User cancelled picker - go back
        if (mounted) Navigator.pop(context);
        return;
      }

      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isLoadingImage = false;
      });

      // Auto-trigger analysis
      _analyzeScreenshot(bytes);
    } catch (e) {
      setState(() {
        _error = 'Erro ao acessar fotos: $e';
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _analyzeScreenshot(Uint8List bytes) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _suggestions = [];
    });

    try {
      // Resize if needed
      final resized = _resizeImage(bytes, 1024);
      final base64 = base64Encode(resized);

      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/keyboard/analyze-screenshot'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'imageBase64': base64,
          'imageMediaType': 'image/jpeg',
          'objective': 'automatico',
          'tone': 'automatico',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysis = data['analysis'] as String? ?? '';
        final parsed = _parseSuggestions(analysis);
        setState(() {
          _suggestions = parsed;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _error = 'Erro do servidor (${response.statusCode})';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro: $e';
        _isAnalyzing = false;
      });
    }
  }

  Uint8List _resizeImage(Uint8List bytes, int maxDim) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final maxSide = decoded.width > decoded.height ? decoded.width : decoded.height;
      if (maxSide <= maxDim) return bytes;
      final resized = img.copyResize(decoded,
        width: decoded.width > decoded.height ? maxDim : null,
        height: decoded.height >= decoded.width ? maxDim : null,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
    } catch (_) {
      return bytes;
    }
  }

  List<String> _parseSuggestions(String text) {
    final lines = text.split('\n');
    final suggestions = <String>[];
    for (final line in lines) {
      final cleaned = line.replaceFirst(RegExp(r'^\d+[\.\)\:\-]\s*'), '').trim();
      if (cleaned.isNotEmpty && cleaned.length > 5) {
        suggestions.add(cleaned);
      }
      if (suggestions.length >= 3) break;
    }
    if (suggestions.isEmpty && text.trim().isNotEmpty) {
      suggestions.add(text.trim());
    }
    return suggestions;
  }

  Future<void> _selectSuggestion(String text) async {
    // Save to shared UserDefaults for keyboard to auto-insert
    try {
      await _nativeChannel.invokeMethod('setSharedDefault', {
        'key': 'kb_pendingInsertText',
        'value': text,
      });
    } catch (_) {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: text));
    }

    if (mounted) {
      // Show brief confirmation then pop back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Volte para a conversa — texto será inserido automaticamente'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      // Small delay so user sees the message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(_profileName != null ? '📸 $_profileName' : '📸 Analisar Print'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingImage
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Image preview
        if (_imageBytes != null)
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.elevatedDark),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(_imageBytes!, fit: BoxFit.cover),
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text('Analisando...', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Error
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: TextStyle(color: AppColors.error)),
          ),

        // Suggestions
        if (_suggestions.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final labels = ['Curta e direta', 'Pergunta inteligente', 'Criativa e ousada'];
                final label = index < labels.length ? labels[index] : 'Sugestão ${index + 1}';
                return _buildSuggestionCard(_suggestions[index], label);
              },
            ),
          ),

        // Choose different photo
        if (!_isAnalyzing && _suggestions.isEmpty && _error == null)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),

        // Bottom: choose another photo
        if (!_isLoadingImage)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: _grabLatestPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Escolher outra foto'),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(String text, String label) {
    return GestureDetector(
      onTap: () => _selectSuggestion(text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.elevatedDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
