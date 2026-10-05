@echo off
setlocal
cd /d "%~dp0.."
echo === MCP Local Dev ===
where node >nul 2>&1 && node -v || echo Node.js: NAO INSTALADO
where npm >nul 2>&1 && npm -v || echo npm: NAO DISPONIVEL
if exist workspace.conf (
  set /p WORKSPACE=<workspace.conf
  echo Workspace: %WORKSPACE%
) else echo Workspace: NAO CONFIGURADO
if exist mcp-local-dev-server\node_modules (echo Dependencias: OK) else echo Dependencias: FALTANDO
echo.
pause
