# 💬 Flirt AI - Dating Assistant

App Flutter multiplataforma (Web + Android + futuro iOS) que usa IA para sugerir respostas inteligentes em conversas de namoro.

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue)
![Web](https://img.shields.io/badge/Web-Enabled-green)
![Android](https://img.shields.io/badge/Android-Enabled-green)
![iOS](https://img.shields.io/badge/iOS-Future-yellow)

## ✨ Features

- 🤖 **IA Integrada**: Claude 3.5 Sonnet via backend Node.js
- 🎨 **5 Tons Diferentes**: Engraçado, Ousado, Romântico, Casual, Confiante
- 🌐 **Web Ready**: Funciona no navegador
- 📱 **Android Ready**: App nativo Android
- 💾 **Histórico**: Salva conversas anteriores
- 🎯 **Material Design 3**: UI moderna e responsiva
- 🌙 **Dark Mode**: Tema escuro automático

## 🚀 Quick Start

### 1. Pré-requisitos

```bash
# Flutter SDK
flutter --version  # >= 3.0

# Backend rodando
cd ../ && npm run dev  # Backend em http://localhost:3000
```

### 2. Instalar Dependências

```bash
cd flirt_ai_app
flutter pub get
```

### 3. Executar

#### Web

```bash
flutter run -d chrome
```

#### Android

```bash
# Conectar dispositivo ou iniciar emulador
flutter run -d android
```

#### iOS (futuro)

```bash
flutter run -d ios
```

## 📱 Plataformas Suportadas

### ✅ Web (Pronto)

**Deploy Options**:
- GitHub Pages (grátis)
- Vercel (grátis)
- Firebase Hosting (grátis)
- Netlify (grátis)

**Como buildar**:
```bash
flutter build web --release
# Arquivos em: build/web/
```

### ✅ Android (Pronto)

**Requisitos**:
- Android 7.0+ (API 24+)

**Como buildar APK**:
```bash
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

**Como instalar**:
```bash
# Via USB
flutter install

# Ou manualmente
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 🔜 iOS (Futuro)

Aguardando Apple Developer Program ($99/ano).

## 🎯 Como Usar

### 1. Configurar Backend

1. Abra **Settings** (⚙️)
2. Digite a URL do backend:
   - Local: `http://localhost:3000`
   - Produção: `https://seu-backend.com`
3. Teste a conexão
4. Salve

### 2. Escolher Tom

Selecione um dos 5 tons:
- 😄 **Engraçado**: Respostas divertidas
- 🔥 **Ousado**: Respostas assertivas
- ❤️ **Romântico**: Respostas carinhosas
- 😎 **Casual**: Respostas leves
- 💪 **Confiante**: Respostas seguras

### 3. Analisar Mensagem

1. Cole a mensagem recebida
2. Toque em **"Analisar com IA"**
3. Receba sugestões inteligentes
4. Copie e envie!

## 🌐 Deploy Web

### GitHub Pages (Grátis)

```bash
# 1. Build
flutter build web --release --base-href "/Dating-app/"

# 2. Commit
cd build/web
git init
git add .
git commit -m "deploy"

# 3. Push para gh-pages
git push -f https://github.com/lucaspioli-oss/Dating-app.git main:gh-pages

# Acesse: https://lucaspioli-oss.github.io/Dating-app/
```

### Vercel (Grátis)

```bash
# 1. Instalar Vercel CLI
npm i -g vercel

# 2. Build
flutter build web --release

# 3. Deploy
cd build/web
vercel --prod

# Link automático gerado!
```

## 🔧 Estrutura do Projeto

```
flirt_ai_app/
├── lib/
│   ├── main.dart                  # App principal
│   ├── providers/
│   │   └── app_state.dart         # State management
│   ├── screens/
│   │   ├── home_screen.dart       # Tela inicial
│   │   ├── chat_screen.dart       # Histórico
│   │   └── settings_screen.dart   # Configurações
│   ├── services/
│   │   └── api_service.dart       # HTTP client
│   └── widgets/
│       ├── tone_selector.dart     # Seletor de tons
│       ├── message_bubble.dart    # Bubble de mensagem
│       └── suggestion_card.dart   # Card de sugestão
├── web/
│   ├── index.html                 # HTML principal
│   └── manifest.json              # PWA manifest
├── android/
│   └── app/
│       └── src/main/AndroidManifest.xml
└── pubspec.yaml                   # Dependências
```

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1

  # HTTP
  http: ^1.2.0

  # Utilities
  shared_preferences: ^2.2.2
  google_fonts: ^6.1.0
  url_launcher: ^6.2.2
```

## 🐛 Troubleshooting

### Web: CORS Error

**Problema**: `Access to XMLHttpRequest blocked by CORS policy`

**Solução**: Configure CORS no backend:

```typescript
// Backend: src/index.ts
fastify.register(require('@fastify/cors'), {
  origin: '*', // Ou 'https://seu-dominio.com'
});
```

### Android: Network Error

**Problema**: `Connection refused`

**Soluções**:
1. Use IP da máquina, não `localhost`
2. Backend: `http://192.168.1.100:3000`
3. Ou use ngrok: `https://abc123.ngrok.io`

### Build Error

**Problema**: `flutter pub get failed`

**Solução**:
```bash
flutter clean
flutter pub get
flutter run
```

## 📚 Recursos

- [Documentação Flutter](https://docs.flutter.dev)
- [Material Design 3](https://m3.material.io)
- [Provider State Management](https://pub.dev/packages/provider)

## 🚀 Roadmap

- [x] Web support
- [x] Android support
- [x] Material Design 3
- [x] Dark mode
- [ ] iOS support (aguardando Apple Developer)
- [ ] PWA offline mode
- [ ] Notificações
- [ ] Autenticação de usuário
- [ ] Planos premium

## 📄 Licença

MIT License - veja [LICENSE](../LICENSE)

## 👨‍💻 Autor

Lucas Pioli - [@lucaspioli-oss](https://github.com/lucaspioli-oss)

---

**Feito com ❤️ usando Flutter + Claude AI**
