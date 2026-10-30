# Source

Vendored from https://github.com/morluto/rea (`.agents/skills/reverse-engineer-anything`),
commit d48e472fa6a664cacbb400560e673533005795ce, MIT license (see LICENSE).

This skill supplies instructions only. The REA MCP server and analysis engines are
installed separately with `npx rea-agents setup` (npm package `rea-agents`).
To update, re-copy the folder from the upstream repo and bump the commit above.

## MCP server

The REA MCP server is registered for this project in `/.mcp.json`, pinned to
`rea-agents@6.8.0` and launched with `npx`, so no machine-specific paths are
committed. Claude Code asks each user to approve the project server on first
use. Requires Node `^22.23.4 || ^24.22.1 || >=26.12.1`. Native engines (Ghidra,
JADX, etc.) are optional and installed per machine; JavaScript/Electron
analysis works without them. To upgrade, bump the version in `.mcp.json`.
