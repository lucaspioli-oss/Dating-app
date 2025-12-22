# 🚀 Guia de Instalação do Flutter - Windows

## ⚡ Opção 1: Script Automático (RECOMENDADO - 10 min)

### Passo 1: Executar Script

1. **Abra PowerShell como Administrador**:
   - Pressione `Win + X`
   - Clique em "Windows PowerShell (Admin)" ou "Terminal (Admin)"

2. **Navegue até a pasta**:
   ```powershell
   cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
   ```

3. **Habilite execução de scripts** (só precisa fazer uma vez):
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
   - Digite `S` e pressione Enter

4. **Execute o script**:
   ```powershell
   .\install_flutter.ps1
   ```

5. **Aguarde** (~5-10 min para download)

6. **IMPORTANTE**: Feche e reabra o PowerShell

### Passo 2: Verificar Instalação

```powershell
flutter --version
```

Deve mostrar algo como:
```
Flutter 3.24.5 • channel stable • ...
```

---

## 📦 Opção 2: Instalação Manual (15 min)

### 1. Download do Flutter SDK

**Link**: https://docs.flutter.dev/get-started/install/windows

Ou download direto:
https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

### 2. Extrair ZIP

1. Baixe o arquivo
2. Extraia para `C:\src\flutter`
   - Crie a pasta `C:\src` se não existir
   - Extraia o ZIP lá dentro
   - Deve ficar: `C:\src\flutter\bin\flutter.bat`

### 3. Adicionar ao PATH

1. Pressione `Win + R`
2. Digite: `sysdm.cpl` e Enter
3. Vá em "Avançado" → "Variáveis de Ambiente"
4. Em "Variáveis do usuário", selecione "Path"
5. Clique em "Editar"
6. Clique em "Novo"
7. Adicione: `C:\src\flutter\bin`
8. Clique "OK" em tudo
9. **Reinicie o terminal**

### 4. Verificar Instalação

Abra novo PowerShell:
```powershell
flutter --version
flutter doctor
```

---

## 🔧 Configuração Pós-Instalação

### 1. Aceitar Licenças Android

```powershell
flutter doctor --android-licenses
```

Pressione `y` para todas as licenças.

### 2. Instalar Dependências (Opcional)

#### Para Web (Chrome)
- Já vem instalado! ✅

#### Para Android
- Baixe Android Studio: https://developer.android.com/studio
- Ou use `scoop install android-studio`

#### Para iOS (Futuro)
- Precisa de macOS + Xcode

### 3. Verificar Tudo

```powershell
flutter doctor -v
```

Deve mostrar:
```
[✓] Flutter (Channel stable, 3.24.5)
[✓] Windows Version (...)
[✓] Chrome - develop for the web
[!] Android toolchain - (pode estar pendente)
```

**Para Web, só precisa do Chrome marcado com ✓**

---

## 🎯 Testando o App

Após instalar Flutter:

### 1. Navegar até o projeto

```powershell
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app"
```

### 2. Instalar dependências

```powershell
flutter pub get
```

### 3. Rodar na Web

```powershell
flutter run -d chrome
```

### 4. (Opcional) Rodar no Android

```powershell
# Conectar celular ou iniciar emulador
flutter run
```

---

## 🐛 Troubleshooting

### Erro: "flutter não é reconhecido"

**Causa**: PATH não configurado ou terminal não foi reiniciado

**Solução**:
1. Feche TODO PowerShell/Terminal/VS Code
2. Abra novo PowerShell
3. Teste: `flutter --version`
4. Se ainda não funcionar, refaça o passo de adicionar ao PATH

### Erro: "Unable to find git"

**Solução**: Instalar Git
```powershell
# Via winget
winget install Git.Git

# Ou baixe: https://git-scm.com/download/win
```

### Erro: "cmdline-tools not found"

**Solução**: Não é necessário para Web! Ignore ou instale Android Studio.

### Erro: "Chrome not found"

**Solução**: Instalar Google Chrome
```powershell
# Via winget
winget install Google.Chrome

# Ou baixe: https://www.google.com/chrome/
```

---

## ⚡ Instalação Alternativa: Chocolatey/Scoop

### Via Chocolatey

```powershell
# Instalar Chocolatey primeiro: https://chocolatey.org/install

choco install flutter
```

### Via Scoop

```powershell
# Instalar Scoop primeiro
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Instalar Flutter
scoop bucket add extras
scoop install flutter
```

---

## 📊 Requisitos de Sistema

### Mínimo
- Windows 10 ou superior (64-bit)
- Disco: 2.5 GB (só Flutter SDK)
- RAM: 4 GB
- Git para Windows

### Recomendado
- Windows 11
- Disco: 10 GB (com Android Studio)
- RAM: 8 GB
- SSD

---

## ✅ Checklist Pós-Instalação

- [ ] `flutter --version` funciona
- [ ] `flutter doctor` mostra Flutter ✓
- [ ] Chrome instalado
- [ ] `flutter pub get` funciona no projeto
- [ ] `flutter run -d chrome` abre o app

---

## 🎓 Recursos

- [Flutter Docs Oficiais](https://docs.flutter.dev)
- [Flutter Windows Setup](https://docs.flutter.dev/get-started/install/windows)
- [Flutter Web Setup](https://docs.flutter.dev/get-started/web)

---

## 📝 Tempo Estimado

| Etapa | Tempo |
|-------|-------|
| Download SDK | 3-5 min |
| Extrair ZIP | 1 min |
| Configurar PATH | 2 min |
| Flutter Doctor | 1 min |
| Pub Get | 1 min |
| **TOTAL** | **~10 min** |

---

**Pronto!** Depois de instalar, volte e execute:

```powershell
cd flirt_ai_app
flutter pub get
flutter run -d chrome
```

🎉 **Seu app vai abrir no navegador!**
