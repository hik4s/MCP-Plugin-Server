@echo off
setlocal EnableExtensions
cd /d "%~dp0.."
title MCP Local Dev - Servidor

if not exist "workspace.conf" (
  echo Workspace ainda nao configurado.
  call "%~dp0INSTALAR_E_CONFIGURAR.bat"
  exit /b %errorlevel%
)

set /p WORKSPACE=<workspace.conf
if not defined WORKSPACE (
  echo Workspace vazio. Execute o instalador novamente.
  pause
  exit /b 1
)

where node >nul 2>&1
if errorlevel 1 (
  echo Node.js nao encontrado. Execute o instalador.
  pause
  exit /b 1
)

if not exist "mcp-local-dev-server\node_modules" (
  echo Dependencias ausentes. Instalando...
  cd /d "%~dp0..\mcp-local-dev-server"
  call npm install || exit /b 1
  cd /d "%~dp0.."
)

set "MCP_WORKSPACE_ROOT=%WORKSPACE%"
echo.
echo ================================================================
echo   MCP LOCAL DEV SERVER
echo Workspace: %MCP_WORKSPACE_ROOT%
echo ================================================================
echo.
echo O servidor MCP esta ativo nesta janela.
echo Feche a janela para interromper o servidor.
echo.
cd /d "%~dp0..\mcp-local-dev-server"
call npx --no-install tsx src/index.ts
set ERR=%ERRORLEVEL%
cd /d "%~dp0.."
echo.
echo MCP encerrado com codigo %ERR%.
exit /b %ERR%
