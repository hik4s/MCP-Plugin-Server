# Integração com o ChatGPT

1. Execute `installer\INSTALAR_E_CONFIGURAR.bat` uma vez.
2. Execute `installer\INICIAR_MCP.bat` para manter o servidor MCP ativo.
3. O plugin privado `MCP Local Dev Bridge` usa `npx` para iniciar este MCP quando o host local de plugins suportar servidores `stdio`.
4. O arquivo `docs/chatgpt-bridge-upstream.json` mostra a configuração correspondente.

## PowerShell remoto

A ferramenta `powershell_run` aceita `computerName` e usa `Invoke-Command`. O computador remoto precisa estar preparado para PowerShell Remoting/WinRM (ou equivalente configurado no ambiente).

## Segurança

- O workspace fica limitado a `MCP_WORKSPACE_ROOT`.
- Escrita de arquivos e comandos com efeitos colaterais exigem `confirmed=true`.
- Senhas, tokens e chaves nao devem ser colocados nos arquivos do plugin.
- O instalador nao abre portas publicas nem cria tunel externo.
