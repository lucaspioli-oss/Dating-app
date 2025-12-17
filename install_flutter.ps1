# ============================================
# Script de Instalação Automática do Flutter
# ============================================

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Instalando Flutter SDK no Windows" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se já está instalado
$flutterPath = "C:\src\flutter"

if (Test-Path $flutterPath) {
    Write-Host "Flutter já está instalado em: $flutterPath" -ForegroundColor Yellow
    Write-Host "Pulando download..." -ForegroundColor Yellow
} else {
    # Criar diretório
    Write-Host "[1/5] Criando diretório C:\src..." -ForegroundColor Green
    New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null

    # Download Flutter SDK
    Write-Host "[2/5] Baixando Flutter SDK (pode demorar)..." -ForegroundColor Green
    $flutterZip = "C:\src\flutter_windows.zip"
    $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip

    # Extrair ZIP
    Write-Host "[3/5] Extraindo Flutter SDK..." -ForegroundColor Green
    Expand-Archive -Path $flutterZip -DestinationPath "C:\src" -Force

    # Limpar arquivo ZIP
    Remove-Item $flutterZip
}

# Adicionar ao PATH
Write-Host "[4/5] Adicionando Flutter ao PATH..." -ForegroundColor Green

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterBinPath = "C:\src\flutter\bin"

if ($currentPath -notlike "*$flutterBinPath*") {
    $newPath = "$currentPath;$flutterBinPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Flutter adicionado ao PATH com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Flutter já está no PATH." -ForegroundColor Yellow
}

# Atualizar PATH na sessão atual
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Executar flutter doctor
Write-Host "[5/5] Executando flutter doctor..." -ForegroundColor Green
Write-Host ""

& "C:\src\flutter\bin\flutter.bat" doctor

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Instalação Concluída!" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANTE: Feche e reabra o PowerShell/Terminal" -ForegroundColor Yellow
Write-Host "Depois execute: flutter --version" -ForegroundColor Yellow
Write-Host ""

pause
