# Deploy iOS pelo Windows (sem Mac) — Desenrola AI

Fluxo: Windows (código) → GitHub → Codemagic (Mac na nuvem) → TestFlight → iPhone

Bundle IDs definidos:
- App principal: `com.desenrolaai.app`
- Keyboard extension: `com.desenrolaai.app.keyboard`
- App Group: `group.com.desenrolaai.app.shared`

---

## Fase 1: Apple Developer Portal (navegador)

Acesse https://developer.apple.com/account

### 1.1 — Criar App IDs

Em Certificates, Identifiers & Profiles > Identifiers, crie 2 App IDs (tipo "App"):

| Campo | App Principal | Keyboard Extension |
|---|---|---|
| Description | Desenrola AI | Desenrola AI Keyboard |
| Bundle ID | `com.desenrolaai.app` | `com.desenrolaai.app.keyboard` |
| Capability | App Groups ativado | App Groups ativado |

### 1.2 — Criar App Group

Em Identifiers > App Groups:

```
Identifier: group.com.desenrolaai.app.shared
```

### 1.3 — Vincular o App Group aos dois App IDs

- Edite cada App ID > App Groups > Configure > selecione `group.com.desenrolaai.app.shared`

---

## Fase 2: App Store Connect (navegador)

Acesse https://appstoreconnect.apple.com

### 2.1 — Criar o App

- My Apps > "+" > New App
- Platform: iOS
- Name: Desenrola AI
- Bundle ID: selecione `com.desenrolaai.app`
- SKU: `desenrolaai`

### 2.2 — Gerar API Key (para o Codemagic fazer deploy)

- Users and Access > Integrations > App Store Connect API > Keys
- Clique "+" > Nome: `Codemagic` > Access: `Developer`
- Baixe o arquivo .p8 (só pode baixar 1 vez!)
- Anote o Key ID e o Issuer ID (aparecem na tela)

---

## Fase 3: Codemagic.io (navegador)

Acesse https://codemagic.io

### 3.1 — Criar conta e conectar GitHub

- Sign up > Connect GitHub > autorize
- Selecione o repo do projeto

### 3.2 — Configurar como Flutter App

- Project type: Flutter App
- App root path: `flutter_keyboard`

### 3.3 — Adicionar Apple Developer credentials

- Settings > Code signing > iOS
- Conecte sua Apple Developer Account (login automático)
- OU faça upload manual do .p8 + Key ID + Issuer ID

### 3.4 — Atualizar variáveis no codemagic.yaml

- BACKEND_URL → https://dating-app-production-ac43.up.railway.app
- Email de notificação → seu email real
- Bundle IDs → com.desenrolaai.app e com.desenrolaai.app.keyboard
- Descomentar a seção app_store_connect para deploy no TestFlight

---

## Fase 4: Ajustar código, commit e build

### 4.1 — Push pro GitHub

```bash
git add . && git commit -m "configure codemagic for iOS deploy" && git push
```

### 4.2 — Triggar build no Codemagic

- Codemagic > seu app > Start new build > ios-workflow
- Aguarde ~10-15 min (Mac M1 na nuvem compila tudo)

---

## Fase 5: Testar no iPhone

1. Instale o app TestFlight no iPhone (App Store)
2. Após build, o app aparece no TestFlight automaticamente
3. Instale e ative o teclado em: Ajustes > Geral > Teclado > Teclados > Adicionar > Desenrola AI

---

## Checklist

- [ ] Conta Apple Developer ativa ($99/ano)
- [ ] App ID criado: com.desenrolaai.app
- [ ] App ID criado: com.desenrolaai.app.keyboard
- [ ] App Group criado: group.com.desenrolaai.app.shared
- [ ] App Group vinculado aos 2 App IDs
- [ ] App criado no App Store Connect
- [ ] API Key .p8 gerada e salva
- [ ] Codemagic conectado ao GitHub
- [ ] Code signing configurado no Codemagic
- [ ] codemagic.yaml atualizado (backend URL, email, bundle IDs)
- [ ] Build disparado no Codemagic
- [ ] TestFlight instalado no iPhone
- [ ] Teclado ativado no iPhone
