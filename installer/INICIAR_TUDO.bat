@echo off
setlocal EnableExtensions
cd /d "%~dp0.."
title MCP Local Dev - Iniciar Tudo

if not exist "workspace.conf" goto SETUP
if not exist "mcp-local-dev-server\node_modules" goto SETUP
where node >nul 2>&1
if errorlevel 1 goto SETUP

for /f "delims=" %%V in ('node -p "process.versions.node.split('.')[0]" 2^>nul') do set NODE_MAJOR=%%V
if not defined NODE_MAJOR goto SETUP
if %NODE_MAJOR% LSS 20 goto SETUP

echo Iniciando o MCP em uma nova janela...
start "MCP Local Dev Server" cmd /k "call "%~dp0INICIAR_MCP.bat""
timeout /t 2 /nobreak >nul

echo Abrindo o ChatGPT/plugin...
start "" "https://chatgpt.com/plugins/plugins_6ac3edf8aafc819192e1929b5e5ba854"
echo.
echo Tudo iniciado.
echo Mantenha a janela do MCP aberta enquanto estiver usando as ferramentas.
pause
exit /b 0

:SETUP
echo Primeira execucao ou dependencias ausentes.
echo Iniciando instalador...
call "%~dp0INSTALAR_E_CONFIGURAR.bat"
if errorlevel 1 exit /b 1
call "%~dp0INICIAR_TUDO.bat"
exit /b %errorlevel%
