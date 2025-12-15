# 💬 Dating App - AI-Powered Keyboard Suite

Sistema completo de teclados customizados com IA para sugestões inteligentes de respostas em conversas de namoro. Inclui backend Node.js com Claude 3.5 Sonnet e implementações nativas para iOS, Android e Flutter.

![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue)
![iOS](https://img.shields.io/badge/iOS-14.0%2B-black)
![Android](https://img.shields.io/badge/Android-7.0%2B-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 🎯 Visão Geral

Este repositório contém um **monorepo** completo com:

1. **Backend API** (Node.js + Fastify + Claude AI)
2. **iOS Keyboard** (Swift nativo)
3. **Android Keyboard** (Kotlin nativo)
4. **Flutter App** (iOS Keyboard Extension via MethodChannel)

Todos conectados a uma API centralizada que usa **Claude 3.5 Sonnet** da Anthropic para gerar sugestões inteligentes de respostas.

## 📁 Estrutura do Repositório

```
Dating-app/
│
├── 📦 Backend (Node.js + TypeScript + Fastify)
│   ├── src/
│   │   ├── index.ts                    # Servidor Fastify
│   │   ├── services/
│   │   │   └── anthropic.ts            # Integração Claude API
│   │   ├── types/
│   │   │   └── index.ts                # Tipos TypeScript
│   │   └── config/
│   │       └── env.ts                  # Configurações
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
│
├── 📱 iOS Native (Swift)
│   └── KeyboardViewController.swift    # Teclado iOS nativo
│
├── 🤖 Android (Kotlin)
│   ├── android/
│   │   ├── FlirtKeyboardService.kt     # Serviço de teclado
│   │   ├── AndroidManifest.xml         # Configurações
│   │   ├── build.gradle                # Dependências
│   │   └── res/
│   │       ├── layout/
│   │       │   └── keyboard_layout.xml # UI do teclado
│   │       ├── values/
│   │       │   └── strings.xml
│   │       └── xml/
│   │           └── method.xml
│   └── README.md
│
├── 🦋 Flutter + iOS Extension
│   └── flutter_keyboard/
│       ├── lib/
│       │   ├── main.dart               # App Flutter
│       │   ├── models/
│       │   ├── screens/
│       │   └── services/
│       ├── ios/
│       │   ├── Runner/
│       │   │   └── AppDelegate.swift   # MethodChannel
│       │   └── FlirtKeyboardExtension/
│       │       └── KeyboardViewController.swift
│       ├── pubspec.yaml
│       ├── XCODE_SETUP.md
│       └── README.md
│
├── 📚 Documentação
│   ├── README.md                       # Este arquivo
│   └── CONTRIBUTING.md
│
└── 🔧 Configurações
    ├── .gitignore
    └── LICENSE
```

## ✨ Features

### Backend API

- ✅ **Endpoint POST `/analyze`**: Recebe texto e tom, retorna sugestões
- ✅ **Integração Claude 3.5 Sonnet**: IA de última geração
- ✅ **5 Tons Personalizados**: System prompts especializados
  - 😄 Engraçado
  - 🔥 Ousado
  - ❤️ Romântico
  - 😎 Casual
  - 💪 Confiante
- ✅ **Fallback Responses**: Respostas charmosas quando API falha
- ✅ **Validação de Schema**: Com Fastify
- ✅ **TypeScript**: Tipagem completa

### iOS Native Keyboard

- ✅ **Custom Keyboard Extension**: Swift puro
- ✅ **Clipboard Integration**: UIPasteboard
- ✅ **Network Requests**: URLSession
- ✅ **Text Insertion**: textDocumentProxy
- ✅ **5 Tons Selecionáveis**: UI nativa

### Android Keyboard

- ✅ **InputMethodService**: Kotlin nativo
- ✅ **Material Design**: ChipGroup e MaterialButton
- ✅ **HTTP Client**: OkHttp + Coroutines
- ✅ **Clipboard Access**: ClipboardManager
- ✅ **Text Insertion**: currentInputConnection.commitText()

### Flutter + iOS Extension

- ✅ **Cross-platform UI**: Flutter para configurações
- ✅ **Native iOS Extension**: Swift keyboard extension
- ✅ **MethodChannel Bridge**: Comunicação Flutter ↔ iOS
- ✅ **App Groups**: Compartilhamento de dados
- ✅ **Settings Management**: Provider state management

## 🚀 Quick Start

### 1. Clone o Repositório

```bash
git clone https://github.com/lucaspioli-oss/Dating-app.git
cd Dating-app
```

### 2. Configure o Backend

```bash
# Instalar dependências
npm install

# Criar arquivo .env
cp .env.example .env

# Editar .env e adicionar sua ANTHROPIC_API_KEY
# ANTHROPIC_API_KEY=sk-ant-...

# Executar em modo desenvolvimento
npm run dev
```

Backend estará rodando em `http://localhost:3000`

### 3. Escolha sua Plataforma

#### iOS Nativo

```bash
# Abrir no Xcode
open KeyboardViewController.swift

# Seguir instruções nos comentários do arquivo
# Criar Custom Keyboard Extension target
# Habilitar Full Access
```

Veja comentários completos em: `KeyboardViewController.swift`

#### Android

```bash
# Abrir no Android Studio
# Importar o projeto da pasta android/

# Ou via linha de comando
cd android
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

Veja documentação completa em: `android/README.md`

#### Flutter (iOS Extension)

```bash
cd flutter_keyboard

# Instalar dependências
flutter pub get

# Executar
flutter run
```

**IMPORTANTE**: Siga o guia de configuração do Xcode: `flutter_keyboard/XCODE_SETUP.md`

## 📖 Documentação por Plataforma

| Plataforma | README | Setup Guide | Código Principal |
|------------|--------|-------------|------------------|
| **Backend** | [README](README.md) | N/A | `src/index.ts` |
| **iOS Native** | Comentários no código | Comentários no código | `KeyboardViewController.swift` |
| **Android** | [android/README.md](android/README.md) | [android/README.md](android/README.md) | `android/FlirtKeyboardService.kt` |
| **Flutter** | [flutter_keyboard/README.md](flutter_keyboard/README.md) | [flutter_keyboard/XCODE_SETUP.md](flutter_keyboard/XCODE_SETUP.md) | `flutter_keyboard/lib/main.dart` |

## 🔧 Configuração de Desenvolvimento

### URLs por Ambiente

#### Backend Local

```bash
# Desenvolvimento
http://localhost:3000
```

#### iOS Simulator

```swift
let apiBaseUrl = "http://localhost:3000"
```

#### iOS Device (Físico)

```swift
// Descobrir IP da máquina: ipconfig getifaddr en0 (Mac)
let apiBaseUrl = "http://192.168.1.100:3000"
```

#### Android Emulator

```kotlin
private val apiBaseUrl = "http://10.0.2.2:3000"
```

#### Android Device (Físico)

```kotlin
// Descobrir IP da máquina: ipconfig (Windows) ou ifconfig (Mac/Linux)
private val apiBaseUrl = "http://192.168.1.100:3000"
```

### Obter Chave da API Anthropic

1. Crie conta em: https://console.anthropic.com
2. Vá em "API Keys"
3. Crie uma nova chave
4. Adicione no `.env`: `ANTHROPIC_API_KEY=sk-ant-...`

## 🎨 Como Funciona

### Fluxo Completo

```
1. Usuário copia mensagem recebida
   ↓
2. Abre teclado customizado em qualquer app
   ↓
3. Seleciona tom (😄🔥❤️😎💪)
   ↓
4. Toca "Sugerir Resposta"
   ↓
5. Teclado envia para Backend:
   POST /analyze
   {
     "text": "mensagem copiada",
     "tone": "engraçado"
   }
   ↓
6. Backend consulta Claude 3.5 Sonnet
   ↓
7. Claude retorna sugestões curtas (2 frases máx)
   ↓
8. Backend retorna para teclado:
   {
     "analysis": "Sugestão 1\nSugestão 2"
   }
   ↓
9. Teclado insere automaticamente no campo de texto
```

### System Prompts

Cada tom tem um system prompt especializado:

**Engraçado**:
- Usa gírias naturais brasileiras
- Evita clichês
- Humor inteligente e criativo

**Ousado**:
- Direto e assertivo
- Cria tensão sexual respeitosa
- Demonstra atitude

**Romântico**:
- Carinhoso mas natural
- Sincero e específico
- Conexão emocional real

**Casual**:
- Leve e fluido
- Espontâneo
- Vibe descontraída

**Confiante**:
- Seguro e direto
- Demonstra valor sem arrogância
- Autêntico e centrado

## 🔐 Privacidade & Segurança

### O que é coletado?

- ✅ **Apenas texto copiado**: Para análise
- ✅ **Tom selecionado**: Para personalização
- ❌ **Nada mais**: Sem tracking, sem analytics, sem armazenamento

### Permissões Necessárias

#### iOS

- `Full Access`: Para clipboard e rede (explicado ao usuário)
- `NSAppTransportSecurity`: HTTP em desenvolvimento (remover em produção)

#### Android

- `INTERNET`: Para chamadas HTTP
- `BIND_INPUT_METHOD`: Para ser um teclado (proteção do sistema)

### Segurança em Produção

⚠️ **IMPORTANTE**: Antes de publicar:

1. **Use HTTPS**: Configure SSL/TLS no backend
2. **Remova HTTP**: Deletar `usesCleartextTraffic` e `NSAllowsArbitraryLoads`
3. **Rate Limiting**: Implemente no backend
4. **Validação de Entrada**: Sanitize dados antes de enviar para Claude
5. **Política de Privacidade**: Transparência com usuários

## 🛠️ Tecnologias

### Backend

- Node.js 18+
- TypeScript 5.5
- Fastify 4.28
- Anthropic SDK 0.32
- dotenv

### iOS

- Swift 5.9
- UIKit
- URLSession
- UIPasteboard

### Android

- Kotlin 1.9
- OkHttp 4.12
- Coroutines 1.7
- Material Components 1.11

### Flutter

- Flutter 3.0+
- Dart 3.0+
- Provider 6.1
- MethodChannel

## 📝 Troubleshooting

### Backend não inicia

**Erro**: `ANTHROPIC_API_KEY não configurada`

**Solução**:
```bash
# Criar .env
echo "ANTHROPIC_API_KEY=sua-chave-aqui" > .env
echo "PORT=3000" >> .env
```

### Teclado não aparece (iOS)

**Solução**:
1. Verificar se keyboard extension foi criado como target separado
2. Clean build folder: Product > Clean Build Folder
3. Reinstalar app

### Clipboard não funciona

**Causa**: Full Access não habilitado

**Solução**: Ajustes > Teclado > [Seu Teclado] > Ativar "Acesso Total"

### Erro de rede

**Possíveis causas**:
1. Backend não está rodando
2. URL incorreta (dispositivo precisa de IP local)
3. Firewall bloqueando porta 3000

**Solução**:
```bash
# Verificar se backend está rodando
curl http://localhost:3000/health

# Liberar porta no firewall (Mac)
sudo pfctl -d

# Descobrir IP local
ipconfig getifaddr en0  # Mac
ipconfig               # Windows
```

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Veja [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes.

### Como Contribuir

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/MinhaFeature`
3. Commit: `git commit -m 'feat: adiciona MinhaFeature'`
4. Push: `git push origin feature/MinhaFeature`
5. Abra um Pull Request

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

## 👨‍💻 Autor

**Lucas Pioli** - [@lucaspioli-oss](https://github.com/lucaspioli-oss)

## 🙏 Agradecimentos

- [Anthropic](https://anthropic.com) - Claude AI API
- [Flutter Team](https://flutter.dev) - Framework incrível
- [Fastify](https://fastify.io) - Web framework rápido
- [Square](https://square.github.io/okhttp/) - OkHttp client

## 📚 Recursos Úteis

### Documentação Oficial

- [Anthropic API Docs](https://docs.anthropic.com)
- [Flutter Documentation](https://docs.flutter.dev)
- [Apple Custom Keyboard Guide](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [Android Input Method](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method)
- [Fastify Documentation](https://www.fastify.io/docs/latest/)

### Tutoriais

- [Platform Channels (Flutter)](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [App Groups (iOS)](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)

## ⭐ Star History

Se este projeto foi útil, considere dar uma estrela!

[![Star History Chart](https://api.star-history.com/svg?repos=lucaspioli-oss/Dating-app&type=Date)](https://star-history.com/#lucaspioli-oss/Dating-app&Date)

---

**Desenvolvido com ❤️ usando Node.js + TypeScript + Flutter + Swift + Kotlin**
