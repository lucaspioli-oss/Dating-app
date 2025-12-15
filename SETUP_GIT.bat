@echo off
REM ============================================
REM Script para Inicializar e Subir para GitHub
REM Repositório: lucaspioli-oss/Dating-app
REM ============================================

echo.
echo ============================================
echo   Configurando Git para Dating App
echo ============================================
echo.

REM Ir para o diretório correto
cd /d "%~dp0"

echo [1/7] Inicializando repositório Git...
git init

echo.
echo [2/7] Configurando usuario Git (se necessario)...
git config user.name "Lucas Pioli"
git config user.email "seu-email@exemplo.com"

echo.
echo [3/7] Adicionando remote do GitHub...
git remote add origin https://github.com/lucaspioli-oss/Dating-app.git

echo.
echo [4/7] Adicionando todos os arquivos...
git add .

echo.
echo [5/7] Criando commit inicial...
git commit -m "feat: initial commit - AI-powered keyboard suite

- Backend Node.js + TypeScript + Fastify + Claude AI
- iOS native keyboard extension (Swift)
- Android keyboard service (Kotlin)
- Flutter app with iOS extension via MethodChannel
- Codemagic CI/CD configuration
- Complete documentation and setup guides"

echo.
echo [6/7] Criando branch main...
git branch -M main

echo.
echo [7/7] Fazendo push para GitHub...
git push -u origin main

echo.
echo ============================================
echo   CONCLUIDO!
echo ============================================
echo.
echo Repositorio subido com sucesso para:
echo https://github.com/lucaspioli-oss/Dating-app
echo.

pause
