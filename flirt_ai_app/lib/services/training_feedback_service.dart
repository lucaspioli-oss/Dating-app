import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/training_feedback_model.dart';

class TrainingFeedbackService {
  static const String baseUrl = AppConfig.backendUrl;

  /// Criar novo feedback
  static Future<TrainingFeedback?> create({
    required String category,
    required String instruction,
    String? subcategory,
    List<String>? examples,
    List<String>? tags,
    String priority = 'medium',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/training-feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category,
          'instruction': instruction,
          if (subcategory != null) 'subcategory': subcategory,
          if (examples != null) 'examples': examples,
          if (tags != null) 'tags': tags,
          'priority': priority,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TrainingFeedback.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Erro ao criar feedback: $e');
      return null;
    }
  }

  /// Listar todos os feedbacks
  static Future<List<TrainingFeedback>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/training-feedback'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => TrainingFeedback.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao listar feedbacks: $e');
      return [];
    }
  }

  /// Listar feedbacks por categoria
  static Future<List<TrainingFeedback>> getByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/training-feedback/category/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => TrainingFeedback.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao listar feedbacks por categoria: $e');
      return [];
    }
  }

  /// Atualizar feedback
  static Future<TrainingFeedback?> update({
    required String id,
    String? instruction,
    List<String>? examples,
    List<String>? tags,
    String? priority,
    bool? isActive,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/training-feedback/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (instruction != null) 'instruction': instruction,
          if (examples != null) 'examples': examples,
          if (tags != null) 'tags': tags,
          if (priority != null) 'priority': priority,
          if (isActive != null) 'isActive': isActive,
        }),
      );

      if (response.statusCode == 200) {
        return TrainingFeedback.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Erro ao atualizar feedback: $e');
      return null;
    }
  }

  /// Deletar feedback
  static Future<bool> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/training-feedback/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao deletar feedback: $e');
      return false;
    }
  }

  /// Obter contexto de treinamento formatado
  static Future<String> getPromptContext({String? category}) async {
    try {
      String url = '$baseUrl/training-feedback/context';
      if (category != null) {
        url += '?category=$category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['context'] ?? '';
      }
      return '';
    } catch (e) {
      print('Erro ao obter contexto: $e');
      return '';
    }
  }
}
