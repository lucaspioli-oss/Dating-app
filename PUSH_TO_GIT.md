# 🚀 Como Subir para o GitHub

## Opção 1: Script Automático (Windows)

Execute o arquivo `SETUP_GIT.bat`:

```bash
# Clique duas vezes no arquivo:
SETUP_GIT.bat

# Ou via terminal:
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"
SETUP_GIT.bat
```

**IMPORTANTE**: Edite o arquivo `SETUP_GIT.bat` antes e mude:
```
git config user.email "seu-email@exemplo.com"
```

---

## Opção 2: Manual (Terminal)

### Passo 1: Criar repositório no GitHub

1. Vá em: https://github.com/new
2. Nome: `Dating-app`
3. Descrição: "AI-powered keyboard suite with Claude 3.5 Sonnet"
4. **NÃO** marque "Initialize with README"
5. Clique "Create repository"

### Passo 2: Executar comandos

Abra o terminal e execute:

```bash
# Navegar para o projeto
cd "C:\Users\lucas\OneDrive\Área de Trabalho\Dating App"

# Inicializar Git
git init

# Configurar usuário (MUDE O EMAIL)
git config user.name "Lucas Pioli"
git config user.email "seu-email@exemplo.com"

# Adicionar remote
git remote add origin https://github.com/lucaspioli-oss/Dating-app.git

# Adicionar todos os arquivos
git add .

# Criar commit
git commit -m "feat: initial commit - AI-powered keyboard suite

- Backend Node.js + TypeScript + Fastify + Claude AI
- iOS native keyboard extension (Swift)
- Android keyboard service (Kotlin)
- Flutter app with iOS extension via MethodChannel
- Codemagic CI/CD configuration
- Complete documentation and setup guides"

# Criar branch main
git branch -M main

# Push para GitHub
git push -u origin main
```

### Passo 3: Verificar

Acesse: https://github.com/lucaspioli-oss/Dating-app

Seu repositório deve estar lá com todos os arquivos!

---

## Opção 3: GitHub Desktop (Interface Gráfica)

### 3.1 Baixar GitHub Desktop

https://desktop.github.com

### 3.2 Adicionar Repositório Local

1. Abra GitHub Desktop
2. File > Add Local Repository
3. Selecione: `C:\Users\lucas\OneDrive\Área de Trabalho\Dating App`
4. Clique "Add repository"

### 3.3 Fazer Commit

1. Escreva commit message:
   ```
   feat: initial commit - AI-powered keyboard suite
   ```
2. Clique "Commit to main"

### 3.4 Publish

1. Clique "Publish repository"
2. Owner: lucaspioli-oss
3. Name: Dating-app
4. Description: "AI-powered keyboard suite with Claude 3.5 Sonnet"
5. Desmarque "Keep this code private" (ou marque se quiser privado)
6. Clique "Publish repository"

---

## ⚠️ ANTES DE SUBIR

### Verificar .env

**IMPORTANTE**: Nunca commite chaves de API!

```bash
# Verificar se .env está no .gitignore
cat .gitignore | grep .env
```

Deve mostrar:
```
.env
.env.local
.env.*.local
```

### Criar .env Localmente

```bash
# Copiar exemplo
cp .env.example .env

# Editar e adicionar sua chave
# ANTHROPIC_API_KEY=sk-ant-...
```

**O .env NÃO será enviado para o GitHub** (está no .gitignore)

---

## 📋 Arquivos que Serão Enviados

```
✅ Backend (Node.js + TypeScript)
✅ iOS Native Keyboard (Swift)
✅ Android Keyboard (Kotlin)
✅ Flutter App + iOS Extension
✅ Documentação (READMEs, guias)
✅ Configuração Codemagic (codemagic.yaml)
✅ .gitignore
✅ LICENSE

❌ .env (segurança)
❌ node_modules (dependências)
❌ build/ (arquivos compilados)
❌ API keys (protegido)
```

---

## ✅ Após o Push

### 1. Verificar no GitHub

https://github.com/lucaspioli-oss/Dating-app

### 2. Configurar Repositório

**Settings > General**:
- Description: "AI-powered keyboard suite with Claude 3.5 Sonnet"
- Website: (seu site, se tiver)
- Topics: `flutter`, `swift`, `kotlin`, `typescript`, `ai`, `keyboard`, `claude`, `ios`, `android`

**Settings > Options**:
- ✅ Issues
- ✅ Discussions (opcional)

### 3. Proteger Branch Main

**Settings > Branches > Branch protection rules**:
- Branch name pattern: `main`
- ✅ Require pull request reviews (opcional)

### 4. Conectar Codemagic

1. Vá em: https://codemagic.io
2. Add application
3. Connect from GitHub
4. Selecione: lucaspioli-oss/Dating-app
5. Configure conforme CODEMAGIC_SETUP.md

---

## 🔄 Próximos Commits

Após o primeiro push, para fazer updates:

```bash
# Adicionar mudanças
git add .

# Commit
git commit -m "feat: descrição da mudança"

# Push
git push
```

### Convenção de Commits

Use prefixos:
- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `chore:` - Manutenção
- `refactor:` - Refatoração

Exemplos:
```bash
git commit -m "feat: adiciona suporte a mais tons"
git commit -m "fix: corrige erro de clipboard no iOS"
git commit -m "docs: atualiza guia de instalação"
```

---

## 🆘 Troubleshooting

### Erro: remote origin already exists

```bash
git remote remove origin
git remote add origin https://github.com/lucaspioli-oss/Dating-app.git
```

### Erro: failed to push

```bash
# Forçar push (CUIDADO: só use no primeiro push)
git push -u origin main --force
```

### Erro: permission denied

Configure SSH keys ou use HTTPS com token:
https://docs.github.com/en/authentication

---

## 📚 Recursos

- [GitHub Docs](https://docs.github.com)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
- [GitHub Desktop](https://desktop.github.com)
