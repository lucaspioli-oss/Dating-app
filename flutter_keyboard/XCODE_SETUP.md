# Configuração do Projeto no Xcode

Este guia mostra como configurar o Keyboard Extension iOS no projeto Flutter.

## Pré-requisitos

- Xcode 15.0 ou superior
- Flutter 3.0 ou superior
- macOS Ventura ou superior
- Conta de desenvolvedor Apple (para testar em dispositivo físico)

## Passo 1: Criar o Projeto Flutter

```bash
cd flutter_keyboard
flutter create .
flutter pub get
```

## Passo 2: Abrir no Xcode

```bash
open ios/Runner.xcworkspace
```

**IMPORTANTE**: Sempre abra o arquivo `.xcworkspace`, NÃO o `.xcodeproj`

## Passo 3: Adicionar Keyboard Extension Target

### 3.1 Criar o Target

1. No Xcode, selecione o projeto `Runner` no navegador
2. Clique no botão `+` abaixo da lista de targets
3. Selecione `Custom Keyboard Extension`
4. Configure:
   - **Product Name**: `FlirtKeyboardExtension`
   - **Team**: Selecione seu time/conta de desenvolvedor
   - **Language**: Swift
   - **Include Unit Tests**: Desmarque
5. Clique em `Finish`
6. Quando perguntado sobre ativar scheme, clique em `Activate`

### 3.2 Substituir o KeyboardViewController.swift

1. No Xcode, delete o arquivo `KeyboardViewController.swift` gerado automaticamente
2. Arraste o arquivo `ios/FlirtKeyboardExtension/KeyboardViewController.swift` deste projeto para o target
3. Certifique-se que está marcado "Copy items if needed"
4. Selecione o target `FlirtKeyboardExtension`

### 3.3 Substituir o Info.plist

1. Delete o `Info.plist` gerado automaticamente
2. Arraste o arquivo `ios/FlirtKeyboardExtension/Info.plist` deste projeto
3. Ou copie o conteúdo manualmente

## Passo 4: Configurar App Groups

App Groups permitem compartilhar dados entre o app principal e o keyboard extension.

### 4.1 No Target Principal (Runner)

1. Selecione o target `Runner`
2. Vá em `Signing & Capabilities`
3. Clique em `+ Capability`
4. Adicione `App Groups`
5. Clique no `+` e adicione: `group.com.flirtkeyboard.shared`

### 4.2 No Target do Keyboard (FlirtKeyboardExtension)

1. Selecione o target `FlirtKeyboardExtension`
2. Vá em `Signing & Capabilities`
3. Clique em `+ Capability`
4. Adicione `App Groups`
5. Clique no `+` e adicione o MESMO grupo: `group.com.flirtkeyboard.shared`

**IMPORTANTE**: O nome do App Group deve ser EXATAMENTE igual nos dois targets.

## Passo 5: Configurar Bundle Identifiers

### 5.1 Target Runner

1. Selecione o target `Runner`
2. Vá em `General` > `Identity`
3. Configure:
   - **Bundle Identifier**: `com.yourcompany.flirtkeyboard`
   - Substitua `yourcompany` pelo seu domínio/identificador

### 5.2 Target FlirtKeyboardExtension

1. Selecione o target `FlirtKeyboardExtension`
2. Vá em `General` > `Identity`
3. Configure:
   - **Bundle Identifier**: `com.yourcompany.flirtkeyboard.FlirtKeyboardExtension`
   - DEVE começar com o mesmo Bundle ID do app principal + `.FlirtKeyboardExtension`

## Passo 6: Atualizar AppDelegate.swift

1. Abra `ios/Runner/AppDelegate.swift`
2. Substitua o conteúdo pelo arquivo `ios/Runner/AppDelegate.swift` deste projeto
3. Ou adicione o código do MethodChannel manualmente

## Passo 7: Configurar Signing

### 7.1 Automatic Signing (Recomendado)

1. Para CADA target (Runner e FlirtKeyboardExtension):
   - Vá em `Signing & Capabilities`
   - Marque `Automatically manage signing`
   - Selecione seu `Team`

### 7.2 Manual Signing (Avançado)

Se você tiver perfis de provisioning específicos, configure manualmente.

## Passo 8: Build e Run

### 8.1 No Simulador

```bash
flutter run
```

Ou no Xcode:
1. Selecione um simulador iOS (iPhone 15, iOS 17.0+)
2. Clique em `Run` (▶️)

### 8.2 No Dispositivo Físico

1. Conecte seu iPhone/iPad
2. Selecione o dispositivo no Xcode
3. Confira que o signing está correto
4. Clique em `Run`

**NOTA**: Keyboard extensions NÃO funcionam no simulador para algumas funcionalidades (clipboard). Teste em dispositivo real.

## Passo 9: Habilitar o Teclado no iOS

### 9.1 Ativar o Teclado

1. No dispositivo, vá em: **Ajustes > Geral > Teclado > Teclados**
2. Toque em **Adicionar Novo Teclado...**
3. Selecione **Flirt Keyboard** (na seção "TECLADOS DE TERCEIROS")
4. Toque em **Flirt Keyboard** na lista
5. Ative **Permitir Acesso Total**
6. Confirme no popup de segurança

### 9.2 Usar o Teclado

1. Abra qualquer app com campo de texto (Mensagens, Notas, etc)
2. Toque no campo de texto
3. Mantenha pressionado o ícone do globo 🌐
4. Selecione **Flirt Keyboard**

## Passo 10: Testar a Integração

1. Abra o app Flutter principal
2. Configure a URL do backend (ex: `http://192.168.1.100:3000`)
3. Salve as configurações
4. Copie uma mensagem qualquer
5. Vá para outro app
6. Troque para o Flirt Keyboard
7. Selecione um tom
8. Toque em "Sugerir Resposta"

## Troubleshooting

### Erro: "No bundle URL present"

**Solução**: Execute `flutter clean` e rebuild:
```bash
flutter clean
cd ios
pod install
cd ..
flutter run
```

### Teclado não aparece na lista

**Possíveis causas**:
1. Bundle Identifier incorreto
2. Info.plist mal configurado
3. Target não foi buildado corretamente

**Solução**:
1. Verifique Bundle IDs
2. Clean e rebuild no Xcode: Product > Clean Build Folder
3. Desinstale o app e reinstale

### App Groups não funciona

**Erro comum**: "group.com.flirtkeyboard.shared" não existe

**Solução**:
1. Verifique que App Groups está habilitado em AMBOS os targets
2. Verifique que o nome é EXATAMENTE igual
3. Se estiver usando um Bundle ID diferente, atualize o nome do grupo também
4. Exemplo: se seu Bundle ID é `com.exemplo.meuapp`, use `group.com.exemplo.meuapp.shared`

### Clipboard não funciona

**Causa**: Full Access não habilitado

**Solução**:
1. Vá em Ajustes > Geral > Teclado > Teclados
2. Toque no Flirt Keyboard
3. Ative "Permitir Acesso Total"

### Chamadas HTTP falham

**Possíveis causas**:
1. Backend não está rodando
2. URL incorreta (use IP da máquina, não localhost)
3. NSAppTransportSecurity bloqueando HTTP

**Solução**:
1. Certifique-se que o backend está rodando: `npm run dev`
2. Use o IP local da máquina (ex: `192.168.1.100:3000`)
3. Verifique `Info.plist` do keyboard extension
4. Para dispositivo físico, deve estar na mesma rede Wi-Fi

### Como descobrir o IP local da máquina

**Mac**:
```bash
ipconfig getifaddr en0
```

**Windows**:
```bash
ipconfig
```

Procure por "IPv4 Address" da sua conexão ativa.

## Estrutura Final do Projeto

```
flutter_keyboard/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── app_settings.dart
│   ├── screens/
│   │   └── home_screen.dart
│   └── services/
│       └── keyboard_service.dart
├── ios/
│   ├── Runner/
│   │   └── AppDelegate.swift
│   ├── FlirtKeyboardExtension/
│   │   ├── KeyboardViewController.swift
│   │   └── Info.plist
│   └── Runner.xcworkspace
└── pubspec.yaml
```

## Próximos Passos

1. **Testar completamente** em dispositivo físico
2. **Melhorar UI** do keyboard extension
3. **Adicionar analytics** (opcional)
4. **Preparar para produção**:
   - Substituir HTTP por HTTPS
   - Remover `NSAllowsArbitraryLoads`
   - Adicionar política de privacidade
   - Criar screenshots para App Store

## Recursos Adicionais

- [Apple - Custom Keyboard Guide](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

## Suporte

Se encontrar problemas, verifique:
1. Logs do Xcode (View > Debug Area > Activate Console)
2. Logs do Flutter (`flutter logs`)
3. Issues no GitHub do projeto
