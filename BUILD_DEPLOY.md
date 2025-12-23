# Processo de Build e Deploy - Desenrola AI

## Problema
A pasta do projeto está no OneDrive, que bloqueia arquivos durante o build do Flutter, causando erro:
```
Could not write file to shaders/ink_sparkle.frag
```

## Solução
Usar a pasta `C:\src\flirt_ai_app` para fazer o build e copiar o resultado.

---

## Passo a Passo

### 1. Sincronizar código (se houver alterações no frontend)

```powershell
# Copiar arquivos atualizados do OneDrive para C:\src
powershell.exe -Command "Copy-Item -Path 'C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\lib\*' -Destination 'C:\src\flirt_ai_app\lib\' -Recurse -Force"
```

### 2. Build do Flutter

```bash
cd C:\src\flirt_ai_app
C:\src\flutter\bin\flutter.bat build web --release
```

### 3. Copiar build de volta para OneDrive

```powershell
powershell.exe -Command "Copy-Item -Path 'C:\src\flirt_ai_app\build\web\*' -Destination 'C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\build\web\' -Recurse -Force"
```

### 4. Deploy para Firebase Hosting

```bash
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
firebase deploy --only hosting
```

---

## Comandos Rápidos (Copiar e Colar)

### Build + Deploy Completo (executar um por vez)

```powershell
# 1. Sync
powershell.exe -Command "Copy-Item -Path 'C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\lib\*' -Destination 'C:\src\flirt_ai_app\lib\' -Recurse -Force"
```

```bash
# 2. Build
cd C:\src\flirt_ai_app && C:\src\flutter\bin\flutter.bat build web --release
```

```powershell
# 3. Copy back
powershell.exe -Command "Copy-Item -Path 'C:\src\flirt_ai_app\build\web\*' -Destination 'C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\build\web\' -Recurse -Force"
```

```bash
# 4. Deploy
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App" && firebase deploy --only hosting
```

---

## Deploy do Backend (Railway)

O backend usa integração com GitHub. Para deploy:

```bash
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
git add .
git commit -m "sua mensagem"
git push origin main
```

O Railway faz deploy automático após o push.

---

## URLs

- **Frontend (Firebase):** https://desenrola-ia.web.app
- **Backend (Railway):** https://dating-app-production-ac43.up.railway.app
- **Firebase Console:** https://console.firebase.google.com/project/desenrola-ia

---

## Estrutura de Pastas

```
C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\
├── firebase.json          # Config Firebase
├── firestore.rules        # Regras Firestore
├── storage.rules          # Regras Storage
├── functions/             # Backend (Cloud Functions / Railway)
│   └── src/
└── flirt_ai_app/          # Frontend Flutter
    ├── lib/
    └── build/web/         # Build gerado

C:\src\flirt_ai_app\       # Pasta de build (fora do OneDrive)
├── lib/
└── build/web/
```

---

## Troubleshooting

### Erro de permissão no build
- Causa: OneDrive sincronizando
- Solução: Usar C:\src para build

### Firebase deploy falha
- Verificar login: `firebase login`
- Verificar projeto: `firebase projects:list`

### Railway não atualiza
- Verificar se push foi feito: `git log -1`
- Verificar status no dashboard Railway
