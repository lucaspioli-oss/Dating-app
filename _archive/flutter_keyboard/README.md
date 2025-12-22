# 💬 Flirt Keyboard - AI-Powered Keyboard for iOS

Teclado customizado para iOS desenvolvido em Flutter com Native iOS Extension que fornece sugestões inteligentes de respostas usando IA (Claude 3.5 Sonnet).

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue)
![iOS](https://img.shields.io/badge/iOS-14.0%2B-black)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 Features

- ✨ **Sugestões com IA**: Receba sugestões inteligentes usando Claude 3.5 Sonnet
- 🎭 **5 Tons Diferentes**: Engraçado, Ousado, Romântico, Casual, Confiante
- ⚡ **Native iOS Keyboard Extension**: Performance nativa com Swift
- 🔄 **Integração Flutter-iOS**: Comunicação via MethodChannel
- 📋 **Clipboard Integration**: Captura automática de mensagens
- 🌐 **Backend Node.js**: API REST com FastifyI
- 🎨 **UI Moderna**: Interface limpa e intuitiva

## 📸 Screenshots

*// TODO: Adicionar screenshots*

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (Dart)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          UI & Settings Management                    │   │
│  │  • Home Screen                                       │   │
│  │  • Backend URL Configuration                         │   │
│  │  • Tone Selection                                    │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                        │
│          MethodChannel (Platform Integration)               │
│                     │                                        │
└─────────────────────┼────────────────────────────────────────┘
                      │
┌─────────────────────┼────────────────────────────────────────┐
│                     ▼                                        │
│              iOS Native (Swift)                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │             AppDelegate.swift                        │   │
│  │  • MethodChannel Handler                            │   │
│  │  • Shared UserDefaults (App Groups)                 │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                        │
│                     │ App Groups (Data Sharing)              │
│                     │                                        │
│  ┌──────────────────┼──────────────────────────────────┐   │
│  │                  ▼                                   │   │
│  │       KeyboardViewController.swift                   │   │
│  │  • Custom Keyboard Extension                         │   │
│  │  • Clipboard Access                                  │   │
│  │  • HTTP Requests (URLSession)                        │   │
│  │  • Text Insertion (textDocumentProxy)                │   │
│  └──────────────────┬──────────────────────────────────┘   │
└─────────────────────┼────────────────────────────────────────┘
                      │
                      │ HTTP POST
                      │
┌─────────────────────┼────────────────────────────────────────┐
│                     ▼                                        │
│            Backend API (Node.js/Fastify)                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              POST /analyze                           │   │
│  │  • Anthropic Claude API Integration                  │   │
│  │  • System Prompts por Tom                            │   │
│  │  • Fallback Responses                                │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## 📂 Estrutura do Projeto

```
flutter_keyboard/
├── lib/                                    # Código Flutter/Dart
│   ├── main.dart                          # App principal
│   ├── models/
│   │   └── app_settings.dart              # Model de configurações
│   ├── screens/
│   │   └── home_screen.dart               # Tela principal
│   └── services/
│       └── keyboard_service.dart          # Serviço de integração nativa
│
├── ios/                                    # Código iOS/Swift
│   ├── Runner/
│   │   └── AppDelegate.swift              # MethodChannel handler
│   └── FlirtKeyboardExtension/
│       ├── KeyboardViewController.swift   # Keyboard Extension
│       └── Info.plist                     # Configurações do Extension
│
├── pubspec.yaml                           # Dependências Flutter
├── XCODE_SETUP.md                         # Guia de configuração
└── README.md                              # Este arquivo
```

## 🚀 Setup

### Pré-requisitos

- Flutter 3.0+
- Xcode 15.0+
- macOS Ventura+
- Conta Apple Developer (para testar em dispositivo)
- Node.js 18+ (para o backend)

### 1. Clone o Repositório

```bash
git clone https://github.com/lucaspioli-oss/Dating-app.git
cd Dating-app
```

### 2. Configure o Backend

```bash
# Na raiz do repositório (Dating App/)
npm install
npm run dev
```

O backend estará rodando em `http://localhost:3000`

### 3. Configure o Flutter

```bash
cd flutter_keyboard
flutter pub get
```

### 4. Configure o Xcode

**IMPORTANTE**: Siga o guia completo em [XCODE_SETUP.md](XCODE_SETUP.md)

Resumo:
1. Abra `ios/Runner.xcworkspace` no Xcode
2. Crie um novo target: Custom Keyboard Extension
3. Configure App Groups em AMBOS os targets
4. Configure Bundle Identifiers
5. Substitua os arquivos gerados pelos deste projeto

### 5. Execute o App

```bash
flutter run
```

### 6. Habilite o Teclado no iOS

1. Ajustes > Geral > Teclado > Teclados
2. Adicionar Novo Teclado > Flirt Keyboard
3. Ativar "Permitir Acesso Total"

## 📖 Como Usar

1. **Configure a URL do Backend**
   - Abra o app Flutter
   - Digite a URL do backend (ex: `http://192.168.1.100:3000`)
   - Selecione o tom padrão
   - Toque em "Salvar Configurações"

2. **Use o Teclado**
   - Copie uma mensagem recebida
   - Abra qualquer app (Messages, WhatsApp, etc)
   - Troque para o Flirt Keyboard (🌐)
   - Selecione o tom desejado
   - Toque em "✨ Sugerir Resposta"

3. **Resultado**
   - A IA analisa a mensagem
   - Sugestões são inseridas automaticamente no campo

## 🔧 Configuração de Desenvolvimento

### URLs por Ambiente

**Simulador iOS**:
```dart
// Use localhost
backendUrl = 'http://localhost:3000'
```

**Dispositivo Físico**:
```dart
// Use IP da máquina na rede local
backendUrl = 'http://192.168.1.100:3000'  // Substitua pelo seu IP
```

### Descobrir IP Local

**Mac**:
```bash
ipconfig getifaddr en0
```

**Windows**:
```bash
ipconfig
# Procure por "IPv4 Address"
```

## 🎨 Tons Disponíveis

| Emoji | Tom | Descrição |
|-------|-----|-----------|
| 😄 | Engraçado | Respostas divertidas e descontraídas |
| 🔥 | Ousado | Respostas assertivas e provocativas |
| ❤️ | Romântico | Respostas carinhosas e genuínas |
| 😎 | Casual | Respostas leves e naturais |
| 💪 | Confiante | Respostas seguras e autênticas |

## 🔐 Privacidade & Segurança

- ✅ **Full Access Transparente**: Explicamos por que precisamos
- ✅ **Sem Armazenamento**: Não guardamos suas mensagens
- ✅ **HTTPS em Produção**: Configure SSL/TLS no backend
- ✅ **App Groups Isolado**: Dados compartilhados apenas entre app e keyboard
- ⚠️ **HTTP Apenas Desenvolvimento**: Use HTTPS em produção

## 🛠️ Tecnologias

### Frontend (Flutter)
- **Flutter 3.0+**: Framework UI
- **Provider**: State management
- **MethodChannel**: Integração nativa

### iOS Native
- **Swift 5.9**: Linguagem
- **UIKit**: Framework UI
- **URLSession**: HTTP requests
- **UIPasteboard**: Clipboard access
- **App Groups**: Data sharing

### Backend
- **Node.js + TypeScript**: Runtime
- **Fastify**: Web framework
- **Anthropic SDK**: Claude API
- **OkHttp**: HTTP client (Android)

## 📝 Troubleshooting

### Teclado não aparece

**Solução**:
```bash
flutter clean
cd ios
pod install
cd ..
flutter run
```

### Clipboard não funciona

**Causa**: Full Access desabilitado

**Solução**: Ajustes > Teclado > Flirt Keyboard > Ativar "Acesso Total"

### Erro de rede

**Possíveis causas**:
1. Backend não está rodando
2. URL incorreta (dispositivo físico precisa de IP local)
3. Firewall bloqueando

**Solução**:
1. Verifique: `curl http://localhost:3000/health`
2. Use IP local ao invés de localhost
3. Desabilite firewall temporariamente

## 🤝 Contribuindo

Contribuições são bem-vindas!

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/MinhaFeature`
3. Commit: `git commit -m 'Adiciona MinhaFeature'`
4. Push: `git push origin feature/MinhaFeature`
5. Abra um Pull Request

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

## 👨‍💻 Autor

Lucas Pioli - [@lucaspioli-oss](https://github.com/lucaspioli-oss)

## 🙏 Agradecimentos

- [Anthropic](https://anthropic.com) - Claude AI API
- [Flutter Team](https://flutter.dev) - Framework incrível
- [Fastify](https://fastify.io) - Web framework rápido

## 📚 Recursos

- [Flutter Documentation](https://docs.flutter.dev)
- [Apple Custom Keyboard Guide](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [Anthropic API Docs](https://docs.anthropic.com)
- [Fastify Documentation](https://www.fastify.io/docs/latest/)

## ⭐ Star History

Se este projeto foi útil, considere dar uma estrela!

[![Star History Chart](https://api.star-history.com/svg?repos=lucaspioli-oss/Dating-app&type=Date)](https://star-history.com/#lucaspioli-oss/Dating-app&Date)

---

**Desenvolvido com ❤️ usando Flutter + Swift + Node.js**
