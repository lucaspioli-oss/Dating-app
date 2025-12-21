import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  /// Analisa uma mensagem e retorna sugestões da IA (expert mode)
  Future<ApiResponse> analyzeMessage({
    required String text,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/analyze');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          analysis: data['analysis'] ?? '',
        );
      } else {
        return ApiResponse.error(
          message: 'Erro ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        message: 'Erro de conexão: ${e.toString()}',
      );
    }
  }

  /// Verifica se o backend está online
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Response model
class ApiResponse {
  final bool success;
  final String? analysis;
  final String? errorMessage;

  ApiResponse._({
    required this.success,
    this.analysis,
    this.errorMessage,
  });

  factory ApiResponse.success({required String analysis}) {
    return ApiResponse._(
      success: true,
      analysis: analysis,
    );
  }

  factory ApiResponse.error({required String message}) {
    return ApiResponse._(
      success: false,
      errorMessage: message,
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
