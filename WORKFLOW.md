# Workflow de Desenvolvimento

Este documento descreve o processo de commit, push, build e deploy do projeto Desenrola AI.

## Estrutura do Projeto

```
Dating App/
├── flirt_ai_app/       # Frontend Flutter (app principal)
│   ├── lib/            # Código Dart
│   ├── assets/         # Imagens e recursos
│   ├── android/        # Configurações Android
│   ├── web/            # Configurações Web
│   └── build/          # Build gerado
├── src/                # Backend (Railway - Fastify/TypeScript)
│   ├── agents/         # Agentes de IA
│   ├── config/         # Configurações
│   ├── services/       # Serviços
│   └── index.ts        # Entry point
├── functions/          # Firebase Functions (secundário)
├── docs/               # Documentação
├── _archive/           # Arquivos arquivados
├── firebase.json       # Configuração Firebase Hosting
├── firestore.rules     # Regras Firestore
└── railway.toml        # Configuração Railway
```

## Requisitos

- **Flutter SDK**: Localizado em `C:\src\flutter`
- **Node.js**: Para o backend e Firebase Functions
- **Firebase CLI**: Para deploy do hosting
- **Git**: Controle de versão

---

## 1. Commit e Push

### Fazer commit das alterações:

```bash
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"

# Ver status das alterações
git status

# Adicionar arquivos específicos
git add flirt_ai_app/lib/screens/arquivo.dart

# Ou adicionar todos os arquivos modificados
git add .

# Fazer commit
git commit -m "tipo: descrição breve da alteração"

# Push para o repositório
git push
```

### Convenção de commits:
- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Alterações em documentação
- `style:` Formatação (não afeta código)
- `refactor:` Refatoração de código
- `chore:` Tarefas de manutenção

---

## 2. Build do Flutter (Frontend)

**IMPORTANTE**: O Flutter está instalado em `C:\src\flutter`. O OneDrive pode causar problemas de permissão ao fazer build diretamente na pasta do projeto.

### Processo de Build:

#### Passo 1: Copiar projeto para C:\src
```powershell
# Remover build anterior (se existir)
Remove-Item -Path "C:\src\flirt_ai_app" -Recurse -Force -ErrorAction SilentlyContinue

# Copiar projeto (excluindo build e .dart_tool)
Copy-Item -Path "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\*" -Destination "C:\src\flirt_ai_app" -Recurse -Force -Exclude "build",".dart_tool"
```

#### Passo 2: Fazer o build
```bash
cd C:\src\flirt_ai_app

# Instalar dependências
flutter pub get

# Build para web
flutter build web --release
```

#### Passo 3: Copiar build de volta
```powershell
# Remover build antigo
Remove-Item -Path "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\build" -Recurse -Force -ErrorAction SilentlyContinue

# Copiar novo build
Copy-Item -Path "C:\src\flirt_ai_app\build" -Destination "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\" -Recurse -Force
```

---

## 3. Deploy Firebase Hosting (Frontend)

Após fazer o build, deploy para o Firebase Hosting:

```bash
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"

# Deploy apenas do hosting
firebase deploy --only hosting
```

**URL do projeto**: https://desenrola-ia.web.app

---

## 4. Deploy Railway (Backend)

O backend é automaticamente deployado quando você faz push para o branch main.

```bash
# Push para main dispara deploy automático
git push
```

Para deploy manual (se necessário):
```bash
railway up
```

---

## Fluxo Completo de Deploy

### Script completo para Windows PowerShell:

```powershell
# 1. Commit e Push
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
git add .
git commit -m "feat: descrição"
git push

# 2. Copiar projeto para C:\src
Remove-Item -Path "C:\src\flirt_ai_app" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path ".\flirt_ai_app\*" -Destination "C:\src\flirt_ai_app" -Recurse -Force -Exclude "build",".dart_tool"

# 3. Build
cd C:\src\flirt_ai_app
flutter pub get
flutter build web --release

# 4. Copiar build de volta
Remove-Item -Path "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\build" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path ".\build" -Destination "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App\flirt_ai_app\" -Recurse -Force

# 5. Deploy Firebase
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
firebase deploy --only hosting
```

---

## Problemas Comuns

### Erro de shader/permissão no build
**Causa**: OneDrive bloqueia arquivos durante sincronização.
**Solução**: Fazer build em `C:\src\flirt_ai_app` conforme descrito acima.

### Erro "Not in a Firebase app directory"
**Causa**: Executando comando na pasta errada.
**Solução**: Executar `firebase deploy` na pasta raiz `Dating App/`.

### Flutter não encontrado
**Causa**: Flutter não está no PATH.
**Solução**: Adicionar `C:\src\flutter\bin` ao PATH do sistema, ou executar diretamente:
```bash
C:\src\flutter\bin\flutter build web --release
```

---

## Links Úteis

- **App Web**: https://desenrola-ia.web.app
- **Firebase Console**: https://console.firebase.google.com/project/desenrola-ia
- **Railway Dashboard**: https://railway.app
- **GitHub**: https://github.com/lucaspioli-oss/Dating-app
