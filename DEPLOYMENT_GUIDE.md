# Guia Completo de Deployment - Flirt AI

Este guia mostra como fazer deploy completo da aplicação com Firebase + Railway + Stripe.

---

## Pré-requisitos

1. **Conta Firebase** (grátis): https://console.firebase.google.com
2. **Conta Railway** (grátis): https://railway.app
3. **Conta Stripe** (grátis): https://stripe.com
4. **Git instalado** na sua máquina
5. **Node.js 20+** instalado
6. **Flutter SDK** instalado

---

## Parte 1: Configurar Firebase

### 1.1. Criar Projeto

1. Acesse https://console.firebase.google.com
2. Clique em **"Add project"** ou **"Adicionar projeto"**
3. Nome do projeto: `flirt-ai-app` (pode ser outro)
4. Aceite os termos e clique **Continue**
5. **Desabilite** Google Analytics (não precisa)
6. Clique **Create project**

### 1.2. Ativar Authentication

1. No menu lateral, clique **Build → Authentication**
2. Clique **Get started**
3. Na aba **Sign-in method**, clique **Email/Password**
4. **Ative** Email/Password (toggle para ON)
5. Clique **Save**

### 1.3. Ativar Firestore

1. No menu lateral, clique **Build → Firestore Database**
2. Clique **Create database**
3. Selecione **Start in production mode**
4. Escolha a localização: **us-central** (ou mais próxima de você)
5. Clique **Enable**

### 1.4. Configurar Web App

1. No menu lateral, clique no ⚙️ **Settings → Project settings**
2. Na seção **Your apps**, clique no ícone **</>** (Web)
3. App nickname: `Flirt AI Web`
4. **Marque** "Also set up Firebase Hosting"
5. Clique **Register app**
6. **IMPORTANTE:** Copie as credenciais que aparecem:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "flirt-ai-app.firebaseapp.com",
     projectId: "flirt-ai-app",
     storageBucket: "flirt-ai-app.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123"
   };
   ```
7. Clique **Continue to console**

### 1.5. Atualizar Código com Credenciais

Abra `flirt_ai_app/lib/main.dart` e substitua as credenciais:

```dart
await Firebase.initializeApp(
  options: kIsWeb
      ? const FirebaseOptions(
          apiKey: "COLE_SEU_API_KEY_AQUI",
          authDomain: "flirt-ai-app.firebaseapp.com",
          projectId: "flirt-ai-app",
          storageBucket: "flirt-ai-app.appspot.com",
          messagingSenderId: "123456789",
          appId: "1:123456789:web:abc123",
        )
      : null,
);
```

### 1.6. Gerar Service Account (para Backend)

1. Em **Settings → Project settings → Service accounts**
2. Clique **Generate new private key**
3. Clique **Generate key** (baixa um arquivo JSON)
4. **GUARDE ESTE ARQUIVO** com segurança (não commitar no Git!)

---

## Parte 2: Configurar Stripe

### 2.1. Criar Conta Stripe

1. Acesse https://dashboard.stripe.com/register
2. Crie sua conta
3. Complete o cadastro

### 2.2. Criar Produtos e Preços

1. No Dashboard da Stripe, vá em **Products**
2. Clique **+ Add product**

**Produto 1 - Mensal:**
- Nome: `Flirt AI - Plano Mensal`
- Descrição: `Acesso completo ao Flirt AI por 1 mês`
- Pricing model: **Recurring**
- Price: `29.90` BRL
- Billing period: **Monthly**
- Clique **Save product**
- **COPIE O PRICE ID** (começa com `price_...`)

**Produto 2 - Anual:**
- Nome: `Flirt AI - Plano Anual`
- Descrição: `Acesso completo ao Flirt AI por 1 ano (2 meses grátis)`
- Pricing model: **Recurring**
- Price: `199.90` BRL
- Billing period: **Yearly**
- Clique **Save product**
- **COPIE O PRICE ID** (começa com `price_...`)

### 2.3. Obter API Keys

1. No Dashboard, clique **Developers → API keys**
2. Você verá:
   - **Publishable key** (começa com `pk_test_...`)
   - **Secret key** (clique "Reveal" para ver, começa com `sk_test_...`)
3. **COPIE AMBAS** - vamos usar depois (NÃO commite no Git!)

### 2.4. Ativar Customer Portal

1. Vá em **Settings → Billing → Customer portal**
2. Clique **Activate test link**
3. Configure:
   - Customers can update payment methods
   - Customers can cancel subscriptions
4. Clique **Save**

### 2.5. Atualizar Price IDs no App

Abra `flirt_ai_app/lib/config/app_config.dart` e atualize:

```dart
class AppConfig {
  // URLs do Backend (Railway)
  static const String productionBackendUrl = 'https://SEU-APP.up.railway.app';
  static const String developmentBackendUrl = 'http://localhost:3000';

  // Stripe Price IDs - ATUALIZE COM SEUS IDs REAIS
  static const String monthlyPriceId = 'price_xxxxxxxxxxxxx'; // Price ID MENSAL
  static const String yearlyPriceId = 'price_xxxxxxxxxxxxx';  // Price ID ANUAL

  // ...resto das configurações
}
```

---

## Parte 3: Deploy Backend no Railway

### 3.1. Fazer Push para GitHub

```bash
# No terminal, na pasta do projeto
git add .
git commit -m "feat: integration with Stripe"
git push origin main
```

### 3.2. Criar Projeto Railway

1. Acesse https://railway.app
2. Login with GitHub
3. **New Project → Deploy from GitHub repo**
4. Escolha seu repositório

### 3.3. Configurar Variáveis de Ambiente

Na aba **Variables** do Railway, adicione:

```
ANTHROPIC_API_KEY=sk-ant-api03-...
FIREBASE_PROJECT_ID=flirt-ai-app
FIREBASE_CLIENT_EMAIL=(do arquivo JSON baixado no passo 1.6)
FIREBASE_PRIVATE_KEY=(do arquivo JSON - incluindo \n)
STRIPE_SECRET_KEY=sk_test_... (da Stripe)
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://flirt-ai-app.web.app
ALLOWED_ORIGINS=https://flirt-ai-app.web.app,https://flirt-ai-app.firebaseapp.com
```

**Como pegar FIREBASE_CLIENT_EMAIL e FIREBASE_PRIVATE_KEY:**

Abra o arquivo JSON que você baixou no passo 1.6:

```json
{
  "type": "service_account",
  "project_id": "flirt-ai-app",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@flirt-ai-app.iam.gserviceaccount.com",
  ...
}
```

- `FIREBASE_CLIENT_EMAIL` = valor de `client_email`
- `FIREBASE_PRIVATE_KEY` = valor de `private_key` (com as quebras de linha `\n`)

### 3.4. Obter URL do Backend

1. Aguarde deploy (~2 min)
2. Na aba **Settings → Domains**, copie a URL
3. Exemplo: `https://flirt-ai-production.up.railway.app`

### 3.5. Atualizar URL no App

Abra `flirt_ai_app/lib/config/app_config.dart` e atualize:

```dart
static const String productionBackendUrl = 'https://flirt-ai-production.up.railway.app';
```

### 3.6. Testar Backend

Acesse: `https://flirt-ai-production.up.railway.app/health`

Deve retornar: `{ "status": "ok", "timestamp": "..." }`

---

## Parte 4: Deploy Frontend no Firebase Hosting

### 4.1. Instalar Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 4.2. Inicializar Firebase no Projeto (se ainda não fez)

```bash
# Na pasta raiz do projeto
firebase init
```

Selecione:
- **Functions** (espaço para marcar)
- **Firestore** (espaço para marcar)
- **Hosting** (espaço para marcar)

Perguntas:
1. "Use an existing project" → Selecione `flirt-ai-app`
2. Firestore rules: **Enter** (usar padrão)
3. Firestore indexes: **Enter** (usar padrão)
4. Functions language: **TypeScript**
5. ESLint: **N** (não)
6. Install dependencies: **Y** (sim)
7. Public directory: `flirt_ai_app/build/web`
8. Single-page app: **Y** (sim)
9. GitHub deploys: **N** (não)

### 4.3. Build e Deploy

```bash
# Build Flutter
cd flirt_ai_app
flutter pub get
flutter build web --release
cd ..

# Build e Deploy Functions
cd functions
npm install
npm run build
cd ..

# Deploy tudo
firebase deploy
```

Aguarde ~2 minutos. No final:

```
Deploy complete!

Hosting URL: https://flirt-ai-app.web.app
Functions URL: https://us-central1-flirt-ai-app.cloudfunctions.net
```

---

## Parte 5: Configurar Webhook da Stripe

### 5.1. URL do Webhook

A URL do webhook é:

```
https://us-central1-flirt-ai-app.cloudfunctions.net/stripeWebhook/stripe
```

(Substitua `flirt-ai-app` pelo ID do seu projeto Firebase)

### 5.2. Criar Webhook na Stripe

1. No Dashboard da Stripe, vá em **Developers → Webhooks**
2. Clique **+ Add endpoint**
3. **Endpoint URL:** Cole a URL acima
4. **Description:** `Flirt AI Subscription Webhook`
5. **Listen to:** Select events
6. Selecione os seguintes eventos:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
   - `invoice.payment_failed`
7. Clique **Add endpoint**

### 5.3. Obter Webhook Secret

1. Após criar o webhook, clique nele
2. Na seção **Signing secret**, clique **Reveal**
3. **COPIE** o secret (começa com `whsec_...`)

### 5.4. Adicionar Secrets nas Functions

```bash
firebase functions:config:set stripe.secret_key="sk_test_..." stripe.webhook_secret="whsec_..."
firebase deploy --only functions
```

### 5.5. Testar Webhook

1. Na Stripe, vá no webhook que você criou
2. Clique na aba **Test**
3. Selecione `checkout.session.completed`
4. Clique **Send test webhook**
5. Verifique os logs: `firebase functions:log`

Deve aparecer: `Stripe webhook received: checkout.session.completed`

---

## Parte 6: Testar Fluxo Completo

### 6.1. Criar Conta de Teste

1. Acesse `https://flirt-ai-app.web.app`
2. Clique **Criar Conta**
3. Preencha: nome, email, senha
4. Clique **Criar Conta Grátis**
5. Você deve ver: "7 dias grátis para testar!"

### 6.2. Testar Trial

1. Faça login
2. Vá em **Perfil**
3. Deve aparecer:
   - "Período Trial"
   - "Expira em 7 dias"
4. Use o app normalmente

### 6.3. Testar Compra (Modo Test)

1. Para testar sem esperar 7 dias, force expiração no Firestore:
   - Abra Firebase Console → Firestore
   - Vá em `users/[seu-user-id]`
   - Mude `subscription.expiresAt` para uma data passada
2. Recarregue o app
3. Deve aparecer tela "Assinatura Expirada"
4. Clique **Assinar Agora** em um dos planos
5. Você será redirecionado para o Stripe Checkout
6. Use cartão de teste:
   - Número: `4242 4242 4242 4242`
   - Data: qualquer futura (ex: 12/25)
   - CVC: qualquer 3 dígitos (ex: 123)
   - CEP: qualquer (ex: 12345-678)
7. Complete o pagamento
8. Volte ao app
9. Acesso liberado!

### 6.4. Verificar no Firestore

1. Firebase Console → Firestore
2. Vá em `users/[seu-user-id]`
3. Deve ter:
   ```
   subscription:
     status: "active"
     plan: "monthly" ou "yearly"
     expiresAt: [data futura]
     stripeSubscriptionId: "sub_..."
     stripeCustomerId: "cus_..."
   ```

---

## Parte 7: Workflow de Atualizações

### Backend (Railway)

```bash
# Faça suas alterações no código
git add .
git commit -m "feat: sua descrição aqui"
git push origin main
```

**Automático!** Railway detecta o push e faz deploy automaticamente (~2 min).

### Frontend (Firebase Hosting)

```bash
cd flirt_ai_app
flutter build web --release
cd ..
firebase deploy --only hosting
```

### Functions (Webhook Stripe)

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

### Deploy Completo

```bash
# Build tudo
cd flirt_ai_app && flutter build web --release && cd ..
cd functions && npm run build && cd ..

# Deploy tudo
firebase deploy

# Push para Railway
git add . && git commit -m "chore: update" && git push origin main
```

---

## Parte 8: Ativar Stripe em Produção

**IMPORTANTE:** Até agora usamos o modo TEST da Stripe.

### 8.1. Ativar Modo Live

1. Dashboard Stripe → Toggle "Test mode" para **OFF** (canto superior direito)
2. Complete a ativação da conta:
   - Informações da empresa
   - Dados bancários (para receber pagamentos)
   - Documentos fiscais

### 8.2. Obter API Keys de Produção

1. **Developers → API keys**
2. Agora você verá keys de produção:
   - `pk_live_...` (publishable key)
   - `sk_live_...` (secret key)

### 8.3. Atualizar Variáveis de Ambiente

**Railway:**
- Vá em Variables
- Atualize `STRIPE_SECRET_KEY=sk_live_...`

**Firebase Functions:**
```bash
firebase functions:config:set stripe.secret_key="sk_live_..."
firebase deploy --only functions
```

### 8.4. Atualizar Webhook para Produção

1. **Developers → Webhooks**
2. Crie um NOVO webhook (igual ao de teste)
3. URL: `https://us-central1-flirt-ai-app.cloudfunctions.net/stripeWebhook/stripe`
4. Eventos: mesmos de antes
5. Copie o novo **Signing secret**
6. Atualize:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_LIVE_..."
   firebase deploy --only functions
   ```

### 8.5. Atualizar Price IDs

Os produtos em modo Live têm Price IDs diferentes!

1. **Products** (modo Live)
2. Crie os mesmos 2 produtos (Mensal e Anual)
3. Copie os novos Price IDs
4. Atualize `flirt_ai_app/lib/config/app_config.dart`
5. Rebuild e deploy:
   ```bash
   cd flirt_ai_app
   flutter build web --release
   cd ..
   firebase deploy --only hosting
   ```

---

## Parte 9: Conectar Domínio Personalizado (Opcional)

### 9.1. No Firebase Hosting

1. **Hosting → Add custom domain**
2. Digite: `seudominio.com.br`
3. Firebase mostrará registros DNS

### 9.2. No seu provedor de domínio (ex: Hostinger)

1. Vá em **DNS/Name Servers**
2. Adicione registro A:
   - Type: `A`
   - Name: `@`
   - Value: `151.101.1.195`
3. Adicione registro A para www:
   - Type: `A`
   - Name: `www`
   - Value: `151.101.1.195`
4. Aguarde propagação (~1-24h)

---

## Monitoramento

### Backend (Railway)

1. Acesse Railway → seu projeto
2. Aba **Logs**: ver logs em tempo real
3. Aba **Metrics**: uso de CPU, memória, requests

### Frontend (Firebase)

```bash
firebase open hosting
```

### Firestore

```bash
firebase open firestore
```

### Functions

```bash
firebase functions:log
```

---

## Custos e Taxas

### Firebase
| Serviço | Limite Grátis | Custo |
|---------|---------------|-------|
| Auth | Ilimitado | R$ 0 |
| Firestore | 50k leituras/dia | R$ 0 |
| Hosting | 10GB/mês | R$ 0 |
| Functions | 2M invocações/mês | R$ 0 |

### Railway
| Plano | Uso | Custo |
|-------|-----|-------|
| Hobby | 500h/mês | R$ 0 |
| Pro | Ilimitado | ~R$ 25/mês |

### Stripe
| Item | Taxa |
|------|------|
| Por transação | 3.99% + R$ 0,39 |
| Mensalidade | R$ 0 |

**Exemplo de venda R$ 29,90:**
- Você recebe: R$ 28,12
- Stripe fica: R$ 1,78

### Receita Estimada (100 assinantes)

| Plano | Assinantes | Receita Líquida |
|-------|------------|-----------------|
| Mensal (R$ 29,90) | 70 | R$ 1.968/mês |
| Anual (R$ 199,90) | 30 | R$ 480/mês |
| **Total** | 100 | **~R$ 2.450/mês** |

---

## Troubleshooting

### Webhook não está funcionando

1. Verifique URL: deve ser `.../stripeWebhook/stripe`
2. Veja logs: `firebase functions:log`
3. Teste na Stripe: Dashboard → Webhooks → Test

### Checkout não abre

1. Verifique backend URL em `app_config.dart`
2. Verifique se Railway está rodando
3. Teste endpoint: `curl https://seu-app.railway.app/health`

### Assinatura não ativa após pagamento

1. Veja logs do webhook: `firebase functions:log`
2. Verifique Firestore: `users/[user-id]/subscription`
3. Teste webhook manualmente na Stripe

### Erro "Invalid API Key"

1. Verifique se `STRIPE_SECRET_KEY` está correto
2. Modo test vs live: certifique-se de usar a key correta
3. Railway: confirme que variável está salva

### Firebase Hosting mostra página em branco

1. Certifique-se de ter feito `flutter build web --release`
2. Verifique se public directory no `firebase.json` está `flirt_ai_app/build/web`

---

## Checklist Final

### Firebase
- [ ] Projeto criado
- [ ] Authentication ativado
- [ ] Firestore ativado
- [ ] Credenciais adicionadas no `main.dart`
- [ ] Service Account JSON baixado
- [ ] Functions deployadas
- [ ] Hosting deployado

### Stripe
- [ ] Conta criada
- [ ] Produtos criados (Mensal + Anual)
- [ ] Price IDs copiados e adicionados em `app_config.dart`
- [ ] API keys copiadas
- [ ] Webhook configurado
- [ ] Webhook secret adicionado nas Functions
- [ ] Teste de pagamento realizado
- [ ] (Produção) Conta ativada
- [ ] (Produção) Produtos de produção criados
- [ ] (Produção) Webhook de produção criado

### Railway
- [ ] Conta criada
- [ ] Repositório conectado
- [ ] Variáveis configuradas
- [ ] Backend deployado
- [ ] URL obtida e adicionada em `app_config.dart`

### Testes
- [ ] Criar conta funciona
- [ ] Trial de 7 dias ativo
- [ ] Tela de assinatura expirada aparece
- [ ] Stripe Checkout abre
- [ ] Pagamento processa
- [ ] Assinatura ativa no Firestore
- [ ] Acesso liberado após pagamento

---

## Arquivos de Configuração Importantes

```
flirt_ai_app/
├── lib/
│   ├── config/
│   │   └── app_config.dart      <- URLs e Price IDs
│   └── main.dart                <- Credenciais Firebase

functions/
└── src/
    └── webhooks/
        └── stripe.ts            <- Webhook handler

.env (não commitar!)
├── STRIPE_SECRET_KEY
├── STRIPE_WEBHOOK_SECRET
└── ... outras variáveis
```

---

**Última atualização:** Dezembro 2025
**Versão:** 2.0 (Stripe)
**Status:** Testado e funcionando

Após todos os itens checados, sua aplicação está **100% funcional** em produção!
