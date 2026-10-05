@echo off
setlocal
cd /d "%~dp0..\mcp-local-dev-server"
if exist node_modules rmdir /s /q node_modules
if exist package-lock.json del /q package-lock.json
echo Dependencias locais removidas. O Node.js nao foi desinstalado.
pause
