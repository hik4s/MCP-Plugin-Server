import { McpServer } from '@modelcontextprotocol/server';
import { serveStdio } from '@modelcontextprotocol/server/stdio';
import * as z from 'zod/v4';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const execFileAsync = promisify(execFile);

const WORKSPACE_ROOT = path.resolve(
  process.env.MCP_WORKSPACE_ROOT || process.cwd(),
);

const MAX_OUTPUT = Number(process.env.MCP_MAX_OUTPUT || 12000);
const MAX_FILE_BYTES = Number(process.env.MCP_MAX_FILE_BYTES || 2_000_000);

function withinWorkspace(target: string): string {
  const resolved = path.resolve(WORKSPACE_ROOT, target);
  const rel = path.relative(WORKSPACE_ROOT, resolved);
  if (rel.startsWith('..') || path.isAbsolute(rel)) {
    throw new Error(`Path is outside MCP_WORKSPACE_ROOT: ${target}`);
  }
  return resolved;
}

function clip(text: string): string {
  if (text.length <= MAX_OUTPUT) return text;
  return `${text.slice(0, MAX_OUTPUT)}\n...[truncated at ${MAX_OUTPUT} chars]`;
}

function isLikelyReadOnlyPowerShell(command: string): boolean {
  const normalized = command.trim();
  const allowed = [
    /^(Get|Test|Resolve|Measure|Select|Where|Format|Out|Compare|ConvertTo)-[A-Za-z0-9-]+\b/i,
    /^(hostname|whoami|ipconfig|systeminfo|ver)\b/i,
    /^(node|npm|npx|python|py|git)\s+(-v|--version|status|diff|branch\b)/i,
  ];
  const dangerous = /\b(Remove-|Stop-|Restart-|Start-|Set-|New-|Add-|Clear-|Disable-|Enable-|Rename-|Move-|Copy-|Install-|Uninstall-|Update-|Stop-Process|Start-Process|reg\b|sc\b|format\b|diskpart\b|shutdown\b|reboot\b|del\b|erase\b|rd\b|rmdir\b|curl\b|wget\b)\b/i;
  return allowed.some((rx) => rx.test(normalized)) && !dangerous.test(normalized);
}

async function runPowerShell(command: string, computerName?: string, timeoutMs = 30000): Promise<string> {
  const executable = process.env.MCP_POWERSHELL || (process.platform === 'win32' ? 'powershell.exe' : 'pwsh');
  const args = ['-NoProfile', '-NonInteractive', '-Command'];

  if (computerName) {
    const escaped = command.replace(/'/g, "''");
    args.push(`Invoke-Command -ComputerName '${computerName.replace(/'/g, "''")}' -ScriptBlock { ${escaped} }`);
  } else {
    args.push(command);
  }

  const { stdout, stderr } = await execFileAsync(executable, args, {
    cwd: WORKSPACE_ROOT,
    windowsHide: true,
    timeout: timeoutMs,
    maxBuffer: 4 * 1024 * 1024,
  });

  const result = stderr ? `${stdout}\n[stderr]\n${stderr}` : stdout;
  return clip(result.trim());
}

function createServer() {
  const server = new McpServer({
    name: 'mcp-local-dev-server',
    version: '0.2.0',
  });

  server.registerTool(
    'workspace_info',
    {
      title: 'Workspace info',
      description: 'Show the configured local workspace root, operating system, and runtime versions.',
      inputSchema: {},
    },
    async () => {
      let nodeVersion = process.version;
      let npmVersion = 'unavailable';
      try {
        npmVersion = (await execFileAsync('npm', ['--version'], { timeout: 10000 })).stdout.trim();
      } catch {
        // Keep unavailable.
      }
      const lines = [
        `workspace: ${WORKSPACE_ROOT}`,
        `platform: ${process.platform} ${os.arch()}`,
        `node: ${nodeVersion}`,
        `npm: ${npmVersion}`,
      ];
      return { content: [{ type: 'text', text: lines.join('\n') }] };
    },
  );

  server.registerTool(
    'list_directory',
    {
      title: 'List directory',
      description: 'List files and folders under the configured workspace. Read-only.',
      inputSchema: {
        relativePath: z.string().default('.'),
      },
    },
    async ({ relativePath }) => {
      const target = withinWorkspace(relativePath);
      const entries = await fs.readdir(target, { withFileTypes: true });
      const result = entries
        .sort((a, b) => a.name.localeCompare(b.name))
        .map((entry) => `${entry.isDirectory() ? '[DIR]' : '[FILE]'} ${entry.name}`)
        .join('\n');
      return { content: [{ type: 'text', text: result || '(empty)' }] };
    },
  );

  server.registerTool(
    'read_file',
    {
      title: 'Read file',
      description: 'Read a UTF-8 text file under the configured workspace. Read-only.',
      inputSchema: {
        relativePath: z.string().min(1),
        maxBytes: z.number().int().positive().max(MAX_FILE_BYTES).default(500_000),
      },
    },
    async ({ relativePath, maxBytes }) => {
      const target = withinWorkspace(relativePath);
      const stat = await fs.stat(target);
      if (stat.size > maxBytes) {
        throw new Error(`File is ${stat.size} bytes; requested limit is ${maxBytes}.`);
      }
      const text = await fs.readFile(target, 'utf8');
      return { content: [{ type: 'text', text: clip(text) }] };
    },
  );

  server.registerTool(
    'write_file',
    {
      title: 'Write file',
      description: 'Write or replace a UTF-8 file under the workspace. Requires confirmed=true because this changes local files.',
      inputSchema: {
        relativePath: z.string().min(1),
        content: z.string(),
        confirmed: z.boolean().default(false),
      },
    },
    async ({ relativePath, content, confirmed }) => {
      if (!confirmed) {
        return {
          isError: true,
          content: [{ type: 'text', text: 'Write blocked. Re-run with confirmed=true after the user approves the file change.' }],
        };
      }
      const target = withinWorkspace(relativePath);
      await fs.mkdir(path.dirname(target), { recursive: true });
      await fs.writeFile(target, content, 'utf8');
      return { content: [{ type: 'text', text: `Wrote ${path.relative(WORKSPACE_ROOT, target)}` }] };
    },
  );

  server.registerTool(
    'powershell_run',
    {
      title: 'Run PowerShell',
      description: 'Run PowerShell locally or through PowerShell Remoting. Read-only commands may run without confirmation; commands with side effects require confirmed=true.',
      inputSchema: {
        command: z.string().min(1),
        computerName: z.string().optional(),
        confirmed: z.boolean().default(false),
        timeoutMs: z.number().int().min(1000).max(120000).default(30000),
      },
    },
    async ({ command, computerName, confirmed, timeoutMs }) => {
      const safe = isLikelyReadOnlyPowerShell(command);
      if (!safe && !confirmed) {
        return {
          isError: true,
          content: [{
            type: 'text',
            text: `Execution blocked because the command may change the system${computerName ? ` on ${computerName}` : ''}. Review it and re-run with confirmed=true after user approval.\n\nCommand:\n${command}`,
          }],
        };
      }
      const output = await runPowerShell(command, computerName, timeoutMs);
      return { content: [{ type: 'text', text: output || '(no output)' }] };
    },
  );

  server.registerTool(
    'git_status',
    {
      title: 'Git status',
      description: 'Show git status for the configured workspace. Read-only.',
      inputSchema: {},
    },
    async () => {
      const { stdout, stderr } = await execFileAsync('git', ['status', '--short', '--branch'], {
        cwd: WORKSPACE_ROOT,
        timeout: 15000,
        maxBuffer: 2 * 1024 * 1024,
      });
      return { content: [{ type: 'text', text: clip(`${stdout}${stderr ? `\n[stderr]\n${stderr}` : ''}`.trim()) || '(clean)' }] };
    },
  );

  server.registerTool(
    'run_command',
    {
      title: 'Run development command',
      description: 'Run a development executable without a shell, from the workspace. This is blocked unless confirmed=true because it may have side effects.',
      inputSchema: {
        executable: z.string().min(1),
        args: z.array(z.string()).default([]),
        confirmed: z.boolean().default(false),
        timeoutMs: z.number().int().min(1000).max(120000).default(30000),
      },
    },
    async ({ executable, args, confirmed, timeoutMs }) => {
      if (!confirmed) {
        return {
          isError: true,
          content: [{ type: 'text', text: `Command blocked. Re-run with confirmed=true after user approval.\n\n${executable} ${args.join(' ')}` }],
        };
      }
      const { stdout, stderr } = await execFileAsync(executable, args, {
        cwd: WORKSPACE_ROOT,
        shell: false,
        windowsHide: true,
        timeout: timeoutMs,
        maxBuffer: 4 * 1024 * 1024,
      });
      return { content: [{ type: 'text', text: clip(`${stdout}${stderr ? `\n[stderr]\n${stderr}` : ''}`.trim()) || '(no output)' }] };
    },
  );

  return server;
}

const handle = serveStdio(createServer);
console.error(`mcp-local-dev-server running on stdio; workspace=${WORKSPACE_ROOT}`);

process.on('SIGINT', () => {
  void handle.close();
});

process.on('SIGTERM', () => {
  void handle.close();
});
