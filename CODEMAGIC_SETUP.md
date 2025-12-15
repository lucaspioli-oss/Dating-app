# 🚀 Guia Completo: Configurar Codemagic.io para Teclado iOS

Este guia vai te ajudar a configurar o Codemagic.io para buildar e distribuir seu app de teclado customizado para o seu iPhone via TestFlight.

## 📋 O Que Você Vai Conseguir

Após seguir este guia:

✅ Build automático do app Flutter + Keyboard Extension
✅ Assinatura automática do código iOS
✅ Deploy automático para TestFlight
✅ Instalar no seu iPhone via TestFlight app
✅ Testar o teclado com IA em produção

## 🎯 Passo 1: Escolher Tipo de Projeto no Codemagic

### Na Tela Inicial do Codemagic

```
┌─────────────────────────────────────────────────┐
│  Select your project type                      │
├─────────────────────────────────────────────────┤
│                                                 │
│  📱 Flutter App                    ← ESCOLHA    │
│     Build, test and deploy Flutter apps        │
│                                                 │
│  🍎 iOS native                                  │
│     Build native iOS apps                       │
│                                                 │
│  🤖 Android native                              │
│     Build native Android apps                   │
│                                                 │
│  ⚛️  React Native                               │
│     Build React Native apps                     │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Escolha: `📱 Flutter App`**

### Por Que Flutter?

1. ✅ Você tem um app Flutter com Keyboard Extension iOS
2. ✅ Codemagic tem integração nativa com Flutter
3. ✅ Mais fácil configurar assinatura de código
4. ✅ Deploy automático para TestFlight
5. ✅ UI para configurar o backend + teclado funcional

## 🔗 Passo 2: Conectar Repositório

### 2.1 Conectar GitHub

```
1. Clique em "Connect from GitHub"
2. Autorize Codemagic a acessar seus repos
3. Selecione: lucaspioli-oss/Dating-app
4. Clique em "Finish"
```

### 2.2 Configurar App Path

**IMPORTANTE**: Seu Flutter não está na raiz!

```
App root path: flutter_keyboard
```

O Codemagic precisa saber que o projeto Flutter está em `flutter_keyboard/`, não na raiz do repositório.

## 🍎 Passo 3: Configurar Apple Developer Account

Você precisa de uma conta Apple Developer para assinar o app e enviar para TestFlight.

### 3.1 Criar Apple Developer Account

Se ainda não tem:

1. Acesse: https://developer.apple.com/programs/
2. Clique em "Enroll"
3. Pague $99/ano (necessário para TestFlight)
4. Aguarde aprovação (1-2 dias)

### 3.2 Criar App ID

1. Acesse: https://developer.apple.com/account/resources/identifiers/list
2. Clique no `+` para criar novo Identifier
3. Selecione "App IDs" > "App"
4. Configure:

**App Principal**:
```
Description: Flirt Keyboard
Bundle ID: com.lucaspioli.flirtkeyboard (EXPLICIT)
Capabilities:
  ✅ App Groups
```

**Keyboard Extension**:
```
Description: Flirt Keyboard Extension
Bundle ID: com.lucaspioli.flirtkeyboard.FlirtKeyboardExtension (EXPLICIT)
Capabilities:
  ✅ App Groups
```

### 3.3 Criar App Group

1. Vá em: https://developer.apple.com/account/resources/identifiers/list/applicationGroup
2. Clique no `+`
3. Configure:
```
Identifier: group.com.lucaspioli.flirtkeyboard.shared
Description: Shared data between app and keyboard
```

### 3.4 Atualizar App IDs com App Group

1. Volte em App IDs
2. Para CADA App ID (app e keyboard):
   - Clique para editar
   - Vá em "App Groups"
   - Clique "Configure"
   - Selecione `group.com.lucaspioli.flirtkeyboard.shared`
   - Salve

## 🔐 Passo 4: Configurar Code Signing no Codemagic

### 4.1 Gerar Certificado e Provisioning Profile

#### Opção A: Automático (Recomendado)

1. No Codemagic, vá em seu app
2. Clique em "Settings" > "Code signing identities"
3. Clique em "iOS code signing"
4. Conecte sua Apple Developer Account:
   - Clique "Connect Apple Developer Portal"
   - Login com suas credenciais Apple
   - Autorize Codemagic

5. Codemagic vai:
   - Criar certificados automaticamente
   - Gerar provisioning profiles
   - Configurar tudo para você

#### Opção B: Manual

Se preferir fazer manualmente:

1. **Certificado de Desenvolvimento**:
   - Xcode > Preferences > Accounts
   - Selecione sua conta Apple
   - Manage Certificates > + > Apple Development
   - Exporte o certificado (.p12)

2. **Provisioning Profile**:
   - https://developer.apple.com/account/resources/profiles/list
   - Create > iOS App Development
   - Selecione App ID
   - Selecione certificado
   - Selecione dispositivos (seu iPhone)
   - Download

3. **Upload no Codemagic**:
   - Settings > Code signing > iOS
   - Upload certificate (.p12)
   - Upload provisioning profile

### 4.2 Configurar App Store Connect API Key (para TestFlight)

1. **Gerar API Key**:
   - Acesse: https://appstoreconnect.apple.com/access/api
   - Clique no `+` em "Keys"
   - Nome: "Codemagic"
   - Access: "Developer"
   - Download a chave (.p8)
   - **IMPORTANTE**: Anote o Key ID e Issuer ID

2. **Adicionar no Codemagic**:
   - Codemagic > Teams > Integrations
   - App Store Connect API key > Add key
   - Upload arquivo .p8
   - Cole Key ID
   - Cole Issuer ID
   - Salve

## ⚙️ Passo 5: Configurar Workflow (Build Pipeline)

### 5.1 Usar o codemagic.yaml

O arquivo `codemagic.yaml` na raiz do repo já está configurado!

```yaml
# Já criado em: Dating-app/codemagic.yaml
workflows:
  ios-workflow:
    name: iOS Build & Deploy
    # ... configurações
```

### 5.2 Ativar YAML Configuration

1. No Codemagic, vá em seu app
2. Clique em "Settings"
3. Em "Build configuration", selecione:
   ```
   ⚙️ codemagic.yaml
   ```
4. Salve

### 5.3 Ajustar Variáveis

Edite `codemagic.yaml` e mude:

```yaml
vars:
  # SEU EMAIL
  BACKEND_URL: "https://seu-backend.com" # ou ngrok para testes

  # SEUS BUNDLE IDs (se mudou)
  BUNDLE_ID: "com.lucaspioli.flirtkeyboard"
  KEYBOARD_BUNDLE_ID: "com.lucaspioli.flirtkeyboard.FlirtKeyboardExtension"

publishing:
  email:
    recipients:
      - seu-email@exemplo.com # MUDE AQUI
```

## 🔧 Passo 6: Atualizar Bundle IDs no Xcode

**IMPORTANTE**: Os Bundle IDs no código devem corresponder aos do Apple Developer.

### 6.1 Abrir Projeto no Xcode

```bash
cd flutter_keyboard
open ios/Runner.xcworkspace
```

### 6.2 Atualizar Bundle IDs

**Target Runner (App Principal)**:
1. Selecione target "Runner"
2. General > Identity
3. Bundle Identifier: `com.lucaspioli.flirtkeyboard`

**Target FlirtKeyboardExtension**:
1. Selecione target "FlirtKeyboardExtension"
2. General > Identity
3. Bundle Identifier: `com.lucaspioli.flirtkeyboard.FlirtKeyboardExtension`

### 6.3 Configurar App Groups

**Para AMBOS os targets** (Runner e FlirtKeyboardExtension):

1. Selecione target
2. Signing & Capabilities
3. Verifique se "App Groups" existe
4. Se não, clique "+ Capability" > App Groups
5. Marque: `group.com.lucaspioli.flirtkeyboard.shared`

### 6.4 Atualizar Código com Bundle IDs

Edite `flutter_keyboard/ios/Runner/AppDelegate.swift`:

```swift
// Linha ~47
if let sharedDefaults = UserDefaults(suiteName: "group.com.lucaspioli.flirtkeyboard.shared") {
    // ...
}
```

Edite `flutter_keyboard/ios/FlirtKeyboardExtension/KeyboardViewController.swift`:

```swift
// Linha ~26
private var sharedDefaults: UserDefaults? {
    return UserDefaults(suiteName: "group.com.lucaspioli.flirtkeyboard.shared")
}
```

## 🚀 Passo 7: Fazer Build no Codemagic

### 7.1 Commit e Push

```bash
cd "Dating App"

# Adicionar codemagic.yaml e mudanças
git add codemagic.yaml
git add flutter_keyboard/ios/
git commit -m "feat: configure Codemagic CI/CD for iOS"
git push
```

### 7.2 Triggerar Build

1. No Codemagic, vá em seu app
2. Clique em "Start new build"
3. Selecione workflow: `ios-workflow`
4. Clique em "Start new build"

### 7.3 Acompanhar Build

- Vai levar ~10-15 minutos
- Você verá logs em tempo real
- Se der erro, leia os logs para debugar

## 📱 Passo 8: Instalar no iPhone via TestFlight

### 8.1 Baixar TestFlight

No seu iPhone:
1. Abra App Store
2. Baixe "TestFlight" (app oficial da Apple)
3. Faça login com sua Apple ID

### 8.2 Aguardar Email

Após build bem-sucedido:
1. Você receberá email: "A new build is available to test"
2. Ou abra TestFlight direto
3. Seu app aparecerá lá

### 8.3 Instalar App

1. Abra TestFlight
2. Toque em "Flirt Keyboard"
3. Toque em "Install"
4. Aguarde download

## ⌨️ Passo 9: Habilitar Teclado no iPhone

### 9.1 Ativar Teclado

1. Ajustes > Geral > Teclado > Teclados
2. "Adicionar Novo Teclado..."
3. Selecione "Flirt Keyboard"
4. **IMPORTANTE**: Toque em "Flirt Keyboard" novamente
5. Ative "Permitir Acesso Total"

### 9.2 Usar Teclado

1. Abra Messages ou qualquer app
2. Toque em campo de texto
3. Mantenha pressionado ícone 🌐
4. Selecione "Flirt Keyboard"

## 🧪 Passo 10: Testar Funcionamento

### 10.1 Configurar Backend URL

Se backend está local:

1. Use **ngrok** para expor localhost:
   ```bash
   # No computador com backend rodando
   npm run dev

   # Em outro terminal
   ngrok http 3000
   ```

2. Copie URL do ngrok: `https://abc123.ngrok.io`

3. No app Flutter (iPhone):
   - Abra app "Flirt Keyboard"
   - Cole URL: `https://abc123.ngrok.io`
   - Salve configurações

### 10.2 Testar Sugestões

1. Copie uma mensagem:
   ```
   "E aí, como você está?"
   ```

2. Abra Messages

3. Troque para Flirt Keyboard

4. Selecione tom (😄🔥❤️😎💪)

5. Toque "Sugerir Resposta"

6. IA vai analisar e inserir sugestão!

## 🐛 Troubleshooting

### Build Falha

**Erro: Code signing**

Solução:
- Verifique se conectou Apple Developer no Codemagic
- Confirme que Bundle IDs estão corretos
- Regenere provisioning profiles

**Erro: Module not found**

Solução:
```yaml
# Em codemagic.yaml, adicione:
scripts:
  - name: Clean Flutter
    script: |
      cd flutter_keyboard
      flutter clean
      flutter pub get
```

### TestFlight Não Recebe App

**Possíveis causas**:
1. Build deu erro (verifique logs)
2. App Store Connect API key incorreta
3. Aguarde até 30min (processamento Apple)

**Solução**:
- Verifique email de confirmação
- Confira App Store Connect: https://appstoreconnect.apple.com

### Teclado Não Aparece

**Causa**: Extension não foi incluída no build

**Solução**:
1. Xcode > Targets
2. Verifique se "FlirtKeyboardExtension" existe
3. Rebuild localmente primeiro
4. Push e rebuilde no Codemagic

## 📚 Recursos Úteis

- [Codemagic Docs - Flutter](https://docs.codemagic.io/flutter-configuration/flutter-projects/)
- [Codemagic - iOS Code Signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [TestFlight Guide](https://developer.apple.com/testflight/)
- [ngrok - Expose localhost](https://ngrok.com)

## ✅ Checklist Final

Antes do primeiro build:

- [ ] Conta Apple Developer ativa ($99/ano)
- [ ] App IDs criados (app + keyboard)
- [ ] App Group criado e configurado
- [ ] Code signing configurado no Codemagic
- [ ] App Store Connect API key adicionada
- [ ] Bundle IDs atualizados no código
- [ ] codemagic.yaml configurado
- [ ] Email correto em codemagic.yaml
- [ ] Backend rodando (local com ngrok ou servidor)
- [ ] TestFlight instalado no iPhone

## 🎉 Sucesso!

Agora você tem:
- ✅ CI/CD automático com Codemagic
- ✅ Build iOS automático
- ✅ Deploy para TestFlight
- ✅ Teclado funcionando no iPhone
- ✅ IA analisando mensagens

Qualquer dúvida, consulte os logs do Codemagic ou a documentação oficial!

---

**Dica Pro**: Configure webhook do GitHub para buildar automaticamente em cada push para `main`.
