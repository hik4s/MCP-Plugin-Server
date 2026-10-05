@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0.."

title MCP Local Dev - Instalar e Configurar

echo.
echo ================================================================
echo   MCP LOCAL DEV + POWERSHELL - INSTALACAO RAPIDA
echo ================================================================
echo.

REM ---------- Node.js ----------
where node >nul 2>&1
if not errorlevel 1 goto CHECK_NODE_VERSION

goto INSTALL_NODE

:CHECK_NODE_VERSION
for /f "delims=" %%V in ('node -p "process.versions.node.split('.')[0]" 2^>nul') do set NODE_MAJOR=%%V
if defined NODE_MAJOR if !NODE_MAJOR! GEQ 20 goto NODE_OK

echo Node.js encontrado, mas a versao e antiga. Um Node.js LTS sera instalado.

:INSTALL_NODE
echo [1/4] Instalando Node.js LTS...
where winget >nul 2>&1
if not errorlevel 1 (
  winget install --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements --accept-package-agreements
  if not errorlevel 1 goto REFRESH_NODE
)

REM Fallback: baixa o instalador MSI da release LTS mais recente no site oficial.
echo Winget nao concluiu a instalacao. Usando o instalador oficial do Node.js...
powershell -NoProfile -Command ^
  "$ErrorActionPreference='Stop'; $items=Invoke-RestMethod 'https://nodejs.org/dist/index.json'; $v=$items | Where-Object { $_.lts -and ([int]($_.version.TrimStart('v').Split('.')[0]) -ge 20) } | Sort-Object {[version]$_.version.TrimStart('v')} -Descending | Select-Object -First 1; if(-not $v){throw 'Nenhuma release LTS compativel encontrada.'}; $arch=$env:PROCESSOR_ARCHITECTURE; if($arch -eq 'ARM64'){$a='arm64'} elseif($arch -eq 'x86'){$a='x86'} else {$a='x64'}; $msi=Join-Path $env:TEMP ('node-lts-' + $v.version + '-' + $a + '.msi'); $url='https://nodejs.org/dist/' + $v.version + '/node-' + $v.version + '-' + $a + '.msi'; Write-Host ('Baixando ' + $url); Invoke-WebRequest -Uri $url -OutFile $msi; Start-Process msiexec.exe -Verb RunAs -Wait -ArgumentList @('/i', $msi, '/qn', '/norestart'); Remove-Item $msi -Force"
if errorlevel 1 goto NODE_INSTALL_FAIL

goto REFRESH_NODE

:REFRESH_NODE
set "PATH=%ProgramFiles%\nodejs;%AppData%\npm;%PATH%"
where node >nul 2>&1
if errorlevel 1 goto NODE_INSTALL_FAIL

:CHECK_AFTER_INSTALL
for /f "delims=" %%V in ('node -p "process.versions.node.split('.')[0]" 2^>nul') do set NODE_MAJOR=%%V
if not defined NODE_MAJOR goto NODE_INSTALL_FAIL
if !NODE_MAJOR! LSS 20 goto NODE_INSTALL_FAIL

:NODE_OK
echo [1/4] Node.js: & node -v
echo          npm:    & npm -v

echo.
echo [2/4] Instalando dependencias do MCP...
cd /d "%~dp0..\mcp-local-dev-server"
call npm install
if errorlevel 1 goto FAIL

cd /d "%~dp0.."
echo.
echo [3/4] Selecione a pasta do seu projeto/workspace.
echo Uma janela sera aberta.
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description='Selecione a pasta que o MCP podera acessar'; $d.ShowNewFolderButton=$true; if($d.ShowDialog() -eq 'OK'){ $d.SelectedPath }"`) do set "WORKSPACE=%%P"

if not defined WORKSPACE (
  echo.
  echo Nenhuma pasta foi selecionada.
  pause
  exit /b 1
)

> "%~dp0..\workspace.conf" echo %WORKSPACE%
> "%~dp0..\mcp-local-dev-server\.env.local" echo MCP_WORKSPACE_ROOT=%WORKSPACE%

REM Gera uma configuracao pronta para a ponte MCP local.
> "%~dp0..\chatgpt-upstream.json" echo {
>> "%~dp0..\chatgpt-upstream.json" echo   "command": "npx",
>> "%~dp0..\chatgpt-upstream.json" echo   "args": ["--yes", "tsx", "%~dp0..\mcp-local-dev-server\src\index.ts"],
>> "%~dp0..\chatgpt-upstream.json" echo   "cwd": "%~dp0..\mcp-local-dev-server",
>> "%~dp0..\chatgpt-upstream.json" echo   "env": { "MCP_WORKSPACE_ROOT": "%WORKSPACE:\=\\%" }
>> "%~dp0..\chatgpt-upstream.json" echo }

echo.
echo [4/4] Configuracao concluida.
echo Workspace: %WORKSPACE%
echo.
echo Execute installer\INICIAR_TUDO.bat para iniciar tudo.
echo.
pause
exit /b 0

:NODE_INSTALL_FAIL
echo.
echo Nao foi possivel instalar/verificar o Node.js 20+ automaticamente.
echo Instale o Node.js LTS em: https://nodejs.org/download/
echo Depois execute este arquivo novamente.
echo.
pause
exit /b 1

:FAIL
echo.
echo Falha durante a instalacao das dependencias npm.
echo.
pause
exit /b 1
