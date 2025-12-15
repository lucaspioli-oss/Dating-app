# 🚀 Setup Rápido - Flirt AI

Guia de 5 minutos para testar o app!

## 📋 Pré-requisitos

- [ ] Flutter SDK instalado
- [ ] Backend Node.js rodando (porta 3000)

## ⚡ Setup em 3 Passos

### 1. Instalar Dependências (1 min)

```bash
cd flirt_ai_app
flutter pub get
```

### 2. Iniciar Backend (1 min)

```bash
# Em outro terminal, na raiz do projeto
cd ..
npm install  # Se ainda não fez
npm run dev
```

Aguarde ver: `🚀 Servidor rodando na porta 3000`

### 3. Executar App (3 min)

#### Opção A: Web (Mais Rápido)

```bash
flutter run -d chrome
```

#### Opção B: Android

```bash
# Conectar dispositivo ou iniciar emulador Android
flutter run
```

## ✅ Testando

1. App abre automaticamente
2. Vá em **Settings** (ícone ⚙️)
3. URL já deve estar: `http://localhost:3000`
4. Toque **"Testar Conexão"** → deve mostrar ✅
5. Volte para **Home**
6. Cole uma mensagem de teste
7. Toque **"Analisar com IA"**
8. Veja a mágica acontecer! ✨

## 🌐 Testar na Web (Internet)

### Deploy no Vercel (2 min - Grátis)

```bash
# 1. Build
flutter build web --release

# 2. Instalar Vercel CLI
npm i -g vercel

# 3. Deploy
cd build/web
vercel --prod
```

Vercel vai gerar um link tipo: `https://flirt-ai-xyz.vercel.app`

**Compartilhe com amigos para testar!**

## 📱 Instalar no Android (5 min)

### Via USB

```bash
# 1. Conectar celular via USB
# 2. Ativar "Depuração USB" no Android
# 3. Executar:

flutter build apk --release
flutter install
```

### Via APK (Compartilhar)

```bash
# 1. Build
flutter build apk --release

# 2. APK estará em:
# build/app/outputs/flutter-apk/app-release.apk

# 3. Envie para seus amigos via WhatsApp/Email
# 4. Eles instalam e testam!
```

## 🔧 Configuração Avançada

### Backend em Produção

Se você fez deploy do backend (Heroku, Render, etc):

1. Abra **Settings** no app
2. Mude URL para: `https://seu-backend.herokuapp.com`
3. Teste conexão
4. Salve

### Build para Produção

#### Web

```bash
flutter build web --release --base-href "/"
```

#### Android (AAB para Google Play)

```bash
flutter build appbundle --release
```

## 🐛 Problemas Comuns

### "Connection refused"

**Causa**: Backend não está rodando ou URL errada

**Solução**:
```bash
# Terminal 1: Backend
npm run dev

# Terminal 2: App
flutter run
```

### CORS Error (Web)

**Solução**: Adicione no backend (`src/index.ts`):

```typescript
import cors from '@fastify/cors';

await fastify.register(cors, {
  origin: '*', // Ou seu domínio específico
});
```

### "Failed to load asset"

**Solução**:
```bash
flutter clean
flutter pub get
flutter run
```

## 📊 Métricas de Build

| Platform | Build Time | Size |
|----------|-----------|------|
| Web      | ~2 min    | ~2 MB |
| Android  | ~3 min    | ~20 MB |
| iOS      | ~4 min    | ~15 MB* |

*iOS: Aguardando Apple Developer Program

## 🎯 Próximos Passos

Após testar localmente:

1. ✅ Deploy Web no Vercel/GitHub Pages
2. ✅ Compartilhe com amigos
3. ✅ Colete feedback
4. ✅ Itere e melhore
5. 💰 Quando validar → Apple Developer ($99)
6. 📱 Publique na App Store

## 📚 Links Úteis

- [Flutter Docs](https://docs.flutter.dev)
- [Vercel Deploy Guide](https://vercel.com/docs)
- [GitHub Pages Flutter](https://docs.flutter.dev/deployment/web#github-pages)

---

**Dúvidas?** Abra uma issue no GitHub!
