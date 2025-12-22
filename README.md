# Desenrola AI - Assistente de Conversas

Sistema de assistente de conversas com IA usando Claude 3.5 Sonnet. Aplicativo Flutter Web com backend Node.js/TypeScript hospedado na Railway.

## Links

- **App Web**: https://desenrola-ia.web.app
- **GitHub**: https://github.com/lucaspioli-oss/Dating-app

## Estrutura do Projeto

```
Dating App/
├── flirt_ai_app/           # Frontend Flutter
│   ├── lib/
│   │   ├── config/         # Configurações (tema, API keys)
│   │   ├── models/         # Modelos de dados
│   │   ├── providers/      # Estado da aplicação
│   │   ├── screens/        # Telas do app
│   │   │   └── auth/       # Telas de autenticação
│   │   ├── services/       # Serviços (API, Firebase, etc)
│   │   └── widgets/        # Componentes reutilizáveis
│   ├── assets/             # Imagens e recursos
│   ├── android/            # Configurações Android
│   ├── web/                # Configurações Web
│   └── build/              # Build gerado
│
├── src/                    # Backend (Railway)
│   ├── agents/             # Agentes de IA
│   ├── config/             # Configurações
│   ├── services/           # Serviços
│   ├── middleware/         # Middlewares
│   └── index.ts            # Entry point
│
├── functions/              # Firebase Functions
│
├── docs/                   # Documentação
│   ├── DEPLOYMENT_GUIDE.md
│   ├── CONVERSATION_SYSTEM.md
│   ├── CODEMAGIC_SETUP.md
│   └── ...
│
├── _archive/               # Arquivos arquivados
│
├── firebase.json           # Firebase Hosting config
├── firestore.rules         # Regras Firestore
├── railway.toml            # Railway config
├── WORKFLOW.md             # Instruções de build/deploy
└── README.md               # Este arquivo
```

## Tecnologias

### Frontend
- Flutter 3.x
- Dart
- Firebase Auth
- Cloud Firestore
- Provider (state management)

### Backend
- Node.js + TypeScript
- Fastify
- Anthropic Claude API
- Stripe (pagamentos)
- Firebase Admin SDK

### Infraestrutura
- Firebase Hosting (frontend)
- Railway (backend)
- Firebase Authentication
- Cloud Firestore

## Quick Start

### Pré-requisitos

- Flutter SDK (em `C:\src\flutter`)
- Node.js 18+
- Firebase CLI
- Git

### Desenvolvimento Local

```bash
# Clone o repositório
git clone https://github.com/lucaspioli-oss/Dating-app.git
cd "Dating App"

# Backend
npm install
npm run dev

# Frontend (em outro terminal)
cd flirt_ai_app
flutter pub get
flutter run -d chrome
```

## Deploy

Consulte o arquivo **[WORKFLOW.md](WORKFLOW.md)** para instruções detalhadas sobre:
- Commit e Push
- Build do Flutter
- Deploy Firebase Hosting
- Deploy Railway

### Resumo Rápido

```bash
# 1. Commit
git add .
git commit -m "feat: descrição"
git push

# 2. Build (em C:\src para evitar problemas com OneDrive)
cd C:\src\flirt_ai_app
flutter build web --release

# 3. Deploy
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
firebase deploy --only hosting
```

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [WORKFLOW.md](WORKFLOW.md) | Instruções de build e deploy |
| [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | Guia completo de deployment |
| [docs/CONVERSATION_SYSTEM.md](docs/CONVERSATION_SYSTEM.md) | Sistema de conversas |
| [flirt_ai_app/README.md](flirt_ai_app/README.md) | Documentação do app Flutter |

## Licença

MIT License
