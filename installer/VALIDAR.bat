@echo off
setlocal
cd /d "%~dp0.."
echo === Validacao rapida ===
echo.
where node >nul 2>&1 && node -v || echo [ERRO] Node.js nao encontrado
echo.
where npm >nul 2>&1 && npm -v || echo [ERRO] npm nao encontrado
echo.
if exist mcp-local-dev-server\package.json (echo [OK] package.json) else echo [ERRO] package.json ausente
if exist mcp-local-dev-server\src\index.ts (echo [OK] src\index.ts) else echo [ERRO] src\index.ts ausente
if exist installer\INICIAR_TUDO.bat (echo [OK] INICIAR_TUDO.bat) else echo [ERRO] INICIAR_TUDO.bat ausente
if exist plugin-bridge\plugin.json (echo [OK] plugin-bridge) else echo [ERRO] plugin-bridge ausente
if exist chatgpt-upstream.json (echo [OK] configuracao upstream) else echo [AVISO] chatgpt-upstream.json ainda nao foi gerado; rode o instalador
if exist mcp-local-dev-server\node_modules (echo [OK] node_modules) else echo [AVISO] dependencias ainda nao instaladas

echo.
pause
