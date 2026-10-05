# MCP Local Dev Bridge

A private Agent Plugin that launches a tiny protocol-transparent stdio bridge and forwards the MCP wire stream to an MCP server running on the same machine.

## What it does

- Connects the Agent Plugins host to your existing local MCP server.
- Preserves MCP protocol negotiation instead of hard-coding a protocol version.
- Works with an upstream server launched by Python, Node, .NET, or another local executable.
- Keeps the upstream command and local environment in `PLUGIN_DATA`, not in the plugin package.
- Adds a workflow skill for code debugging and PowerShell use.

## Configure the upstream MCP

After the plugin is installed by a compatible local Agent Plugins host, locate that plugin instance's `PLUGIN_DATA` directory. Copy `config/upstream.example.json` to:

`<PLUGIN_DATA>/upstream.json`

Then edit `upstream.json` so `command`, `args`, `cwd`, and optional `env` start your existing MCP server.

Examples:

### Node MCP with npx

```json
{
  "command": "npx",
  "args": ["--yes", "tsx", "C:/tools/mcp-local-dev-server/src/index.ts"],
  "cwd": "C:/tools/mcp-local-dev-server",
  "env": {
    "MCP_WORKSPACE_ROOT": "C:/path/to/your/project"
  }
}
```

### Node MCP

```json
{
  "command": "node",
  "args": ["C:/tools/my_mcp/dist/index.js"],
  "cwd": "C:/tools/my_mcp"
}
```

Do not put secrets into the plugin package. Use the upstream MCP's existing credential mechanism or local environment configuration.

## Important limitation

This plugin is a bridge; it does not create a network tunnel by itself. The machine-local host must support launching stdio Agent Plugin MCP servers. An account/private-plugin upload alone does not make a local process reachable from the ChatGPT web/mobile clients.

For remote PowerShell, the upstream MCP should expose the remote-session capability (for example through WinRM/PowerShell Remoting or SSH). The bridge simply forwards that MCP connection.
