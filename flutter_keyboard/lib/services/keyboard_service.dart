import 'package:flutter/services.dart';

/// Serviço para comunicação com o teclado nativo iOS via MethodChannel
class KeyboardService {
  // Nome do canal deve corresponder ao código nativo iOS
  static const platform = MethodChannel('com.desenrolaai/native');

  /// Verifica se o teclado customizado está habilitado
  Future<bool> isKeyboardEnabled() async {
    try {
      final bool result = await platform.invokeMethod('isKeyboardEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Erro ao verificar teclado: ${e.message}");
      return false;
    }
  }

  /// Abre as configurações do sistema para habilitar o teclado
  Future<void> openKeyboardSettings() async {
    try {
      await platform.invokeMethod('openKeyboardSettings');
    } on PlatformException catch (e) {
      print("Erro ao abrir configurações: ${e.message}");
    }
  }

  /// Envia a URL do backend para o teclado nativo
  /// Isso permite que o teclado saiba onde fazer as requisições
  Future<void> setBackendUrl(String url) async {
    try {
      await platform.invokeMethod('setBackendUrl', {'url': url});
    } on PlatformException catch (e) {
      print("Erro ao configurar URL: ${e.message}");
    }
  }

  /// Define o tom padrão no teclado nativo
  Future<void> setDefaultTone(String tone) async {
    try {
      await platform.invokeMethod('setDefaultTone', {'tone': tone});
    } on PlatformException catch (e) {
      print("Erro ao configurar tom: ${e.message}");
    }
  }

  /// Compartilha o token de autenticação com o teclado via App Groups
  /// Deve ser chamado após login e quando o token for renovado
  Future<void> shareAuthWithKeyboard(String authToken, String userId) async {
    try {
      await platform.invokeMethod('shareAuthWithKeyboard', {
        'authToken': authToken,
        'userId': userId,
      });
    } on PlatformException catch (e) {
      print("Erro ao compartilhar auth com teclado: ${e.message}");
    }
  }

  /// Remove a autenticação do teclado (chamado no logout)
  Future<void> clearKeyboardAuth() async {
    try {
      await platform.invokeMethod('clearKeyboardAuth');
    } on PlatformException catch (e) {
      print("Erro ao limpar auth do teclado: ${e.message}");
    }
  }
}
