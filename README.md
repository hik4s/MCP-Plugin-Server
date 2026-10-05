# MCP Local Dev + PowerShell para ChatGPT

Pacote unificado para criar um MCP local em Node.js, instalar o ambiente automaticamente e integrar o servidor ao plugin privado `MCP Local Dev Bridge`.

## Instalacao em poucos cliques

1. Extraia este ZIP para uma pasta permanente.
2. Dê duplo clique em `installer\INICIAR_TUDO.bat`.
3. Na primeira execucao, o instalador verifica/instala Node.js LTS, instala as dependencias npm e abre um seletor para escolher seu projeto.
4. Nas execucoes seguintes, `INICIAR_TUDO.bat` inicializa o MCP e abre o plugin no navegador.

## Arquivos importantes

- `installer\INICIAR_TUDO.bat` — fluxo recomendado.
- `installer\INSTALAR_E_CONFIGURAR.bat` — reinstalacao/reconfiguracao.
- `installer\INICIAR_MCP.bat` — inicia somente o servidor.
- `installer\STATUS.bat` — verifica Node, npm, workspace e dependencias.
- `chatgpt-upstream.json` — configuracao pronta para a ponte quando o host local solicitar um upstream MCP.
- `mcp-local-dev-server\requirements.txt` — requisitos do ambiente.

## Ferramentas MCP

- listagem e leitura do workspace;
- escrita de arquivos com confirmacao;
- PowerShell local;
- PowerShell Remoting;
- Git status;
- execucao de comandos de desenvolvimento com confirmacao.

## Requisitos

Node.js 20 ou superior. O instalador prefere `winget` e, se necessario, baixa o MSI da release LTS mais recente diretamente do dominio oficial `nodejs.org`.

## PowerShell remoto

A ferramenta usa `Invoke-Command` quando `computerName` e informado. O host remoto precisa estar previamente preparado para PowerShell Remoting/WinRM e para a autenticacao usada no seu ambiente.

## Seguranca

O servidor limita arquivos ao workspace selecionado. Escritas e comandos com efeitos colaterais exigem `confirmed=true`. O instalador nao abre portas publicas, nao cria tunel externo e nao salva senhas ou tokens.

## Limitacao de conectividade

Este projeto usa MCP por `stdio`. A execucao local funciona em um host que consiga iniciar servidores MCP locais. O plugin privado nao cria, sozinho, uma conexao de internet reversa entre o ChatGPT web e o Windows.

Para acesso realmente remoto pelo ChatGPT web seria necessario um MCP remoto (por exemplo, Streamable HTTP) protegido por autenticacao e rede adequada. Isso nao e habilitado neste pacote por seguranca.

Plugin privado:
https://chatgpt.com/plugins/plugins_6ac3edf8aafc819192e1929b5e5ba854
