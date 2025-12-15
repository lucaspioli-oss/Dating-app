# Flirt Keyboard - Teclado Android com IA

Teclado customizado para Android que fornece sugestões inteligentes de respostas usando IA (Claude).

## Estrutura do Projeto

```
android/
├── FlirtKeyboardService.kt           # Serviço principal do teclado
├── AndroidManifest.xml               # Configurações e permissões
├── build.gradle                      # Dependências e configurações de build
├── res/
│   ├── layout/
│   │   └── keyboard_layout.xml       # Layout da UI do teclado
│   ├── xml/
│   │   └── method.xml                # Configuração do Input Method
│   ├── values/
│   │   └── strings.xml               # Strings do app
│   └── color/
│       └── chip_background_selector.xml  # Cores dos chips
```

## Funcionalidades Implementadas

### 1. **Captura de Clipboard** 📋
```kotlin
private fun getClipboardText(): String?
```
- Acessa `ClipboardManager` do sistema
- Valida se há texto copiado
- Retorna texto ou mostra erro via Toast

### 2. **Requisição HTTP com OkHttp** 🌐
```kotlin
private fun analyzeText(text: String, tone: String, onSuccess: (String) -> Unit, onError: (String) -> Unit)
```
- POST para `http://10.0.2.2:3000/analyze`
- Body JSON: `{ "text": "...", "tone": "..." }`
- Usa Kotlin Coroutines para operação assíncrona
- Parse JSON da resposta
- Callbacks de sucesso/erro

### 3. **Inserção de Texto** ⌨️
```kotlin
private fun insertText(text: String)
```
- Usa `currentInputConnection.commitText(text, 1)`
- API oficial do Android para teclados customizados
- Funciona em qualquer app

### 4. **Interface do Usuário** 🎨
- **ChipGroup** com 5 tons: 😄 🔥 ❤️ 😎 💪
- **MaterialButton** para sugestões
- **Feedback visual** durante loading
- **Instruções** inline para o usuário

## Configuração no Android Studio

### 1. Criar Novo Projeto
```
File > New > New Project > Empty Activity
Nome: FlirtKeyboard
Package: com.example.flirtkeyboard
Language: Kotlin
Minimum SDK: API 24 (Android 7.0)
```

### 2. Copiar Arquivos

Copie todos os arquivos desta pasta para o projeto:

```bash
# Código Kotlin
app/src/main/java/com/example/flirtkeyboard/FlirtKeyboardService.kt

# Manifest
app/src/main/AndroidManifest.xml

# Layouts
app/src/main/res/layout/keyboard_layout.xml
app/src/main/res/xml/method.xml
app/src/main/res/values/strings.xml
app/src/main/res/color/chip_background_selector.xml

# Build
app/build.gradle
```

### 3. Sync do Gradle

Clique em **"Sync Now"** quando aparecer a notificação.

### 4. Build e Instalação

```bash
# Via Android Studio
Build > Make Project
Run > Run 'app'

# Via linha de comando
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Ativação no Dispositivo

### 1. Ativar o Teclado
1. Abra **Configurações** no Android
2. Vá em **Sistema > Idiomas e entrada > Teclado virtual**
3. Toque em **"Gerenciar teclados"**
4. Ative **"Flirt Keyboard - Sugestões com IA"**

### 2. Usar o Teclado
1. Abra qualquer app com campo de texto (WhatsApp, Messages, etc)
2. Toque no campo de texto
3. Toque no ícone do teclado (🌐) na barra de navegação
4. Selecione **"Flirt Keyboard"**

## Como Usar

1. **Copie** uma mensagem que você recebeu (long-press > Copiar)
2. **Abra** o campo de texto onde quer responder
3. **Troque** para o Flirt Keyboard
4. **Selecione** o tom desejado (😄🔥❤️😎💪)
5. **Toque** em "✨ Sugerir Resposta"
6. Aguarde a IA processar (backend deve estar rodando!)
7. A resposta será **inserida automaticamente** no campo

## Configuração de Rede

### Emulador Android
URL já configurada: `http://10.0.2.2:3000`
- `10.0.2.2` aponta para `localhost` da máquina host
- Certifique-se que o backend Node.js está rodando na porta 3000

### Dispositivo Físico
Altere a URL em `FlirtKeyboardService.kt`:

```kotlin
// De:
private val apiBaseUrl = "http://10.0.2.2:3000"

// Para (substitua pelo IP da sua máquina):
private val apiBaseUrl = "http://192.168.1.100:3000"
```

Para descobrir seu IP local:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

## Permissões

### Necessárias no AndroidManifest.xml
- ✅ `INTERNET` - Para chamadas HTTP
- ✅ `BIND_INPUT_METHOD` - Para ser um teclado customizado (proteção do sistema)

### Não Requer Permissão
- ✅ Clipboard - Acesso direto via `ClipboardManager` (Android mostra toast automático no Android 10+)

## Troubleshooting

### Teclado não aparece na lista
- Verifique se `android:permission="android.permission.BIND_INPUT_METHOD"` está no `<service>` do manifest
- Reinstale o app
- Reinicie o dispositivo

### Erro de rede
- ✅ Backend Node.js está rodando?
- ✅ Emulador: use `10.0.2.2:3000`
- ✅ Dispositivo físico: use IP da máquina na rede local
- ✅ `usesCleartextTraffic="true"` está no manifest? (permite HTTP)

### Clipboard não funciona
- É normal o Android 10+ mostrar um toast ao acessar clipboard
- Deve funcionar normalmente, apenas informa o usuário

### Layout não carrega
- ✅ Verifique se `keyboard_layout.xml` existe em `res/layout/`
- ✅ Verifique se `method.xml` existe em `res/xml/`
- ✅ Clean e rebuild: Build > Clean Project > Rebuild Project

### Backend não responde
- ✅ Backend está rodando? `npm run dev`
- ✅ Porta 3000 está livre?
- ✅ Teste manualmente: `curl -X POST http://localhost:3000/analyze -H "Content-Type: application/json" -d '{"text":"teste","tone":"casual"}'`

## Dependências Principais

```gradle
// OkHttp - Cliente HTTP
implementation 'com.squareup.okhttp3:okhttp:4.12.0'

// Coroutines - Operações assíncronas
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'

// Material Design - UI Components
implementation 'com.google.android.material:material:1.11.0'
```

## Próximos Passos (Opcional)

1. **Adicionar configurações**: Permitir usuário mudar URL do backend
2. **Cache local**: Armazenar respostas frequentes
3. **Histórico**: Salvar sugestões anteriores
4. **Teclado completo**: Adicionar letras e números além das sugestões
5. **Analytics**: Rastrear uso e melhorar sugestões
6. **UI melhorada**: Animações e transições

## Segurança

⚠️ **IMPORTANTE para Produção:**

1. **Use HTTPS**: Nunca envie dados sensíveis via HTTP
2. **Remova `usesCleartextTraffic`**: Apenas para desenvolvimento
3. **Valide entrada**: Sanitize texto antes de enviar para API
4. **Rate limiting**: Implemente no backend para prevenir abuso
5. **Política de privacidade**: Informe usuários sobre uso de dados
6. **Criptografia**: Considere criptografar dados sensíveis

## Licença

MIT
