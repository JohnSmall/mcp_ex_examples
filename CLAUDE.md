# MCP Ex Examples — Agent Instructions

## Project Overview

Four example projects demonstrating the `mcp_ex` library (v0.2.1) — an Elixir implementation of the Model Context Protocol.

## Build Order

**Always build servers first, then clients.**

1. `server_example_1` — Stdio weather/calculator server (zero extra deps)
2. `server_example_2` — HTTP knowledge base server (requires req, plug, bandit)
3. `client_example_1` — Basic cross-connect client
4. `client_example_2` — Advanced client with callbacks

## Connection Topology

```
client_example_1 ──stdio──► server_example_1
client_example_1 ──HTTP───► server_example_2
client_example_2 ──stdio──► server_example_1
client_example_2 ──HTTP───► server_example_2
```

## Elixir Guidelines

- All projects use `mcp_ex` as a path dependency: `{:mcp_ex, path: "../../mcp_ex"}`
- Stdio transport needs zero additional deps beyond `mcp_ex`
- HTTP transport needs `req`, `plug`, and `bandit`
- Never nest multiple modules in the same file
- Don't use `String.to_atom/1` on user input
- Use `Code.eval_string/1` with rescue for calculator safety

## Running

```bash
# Terminal 1: Start HTTP server
cd server_example_2 && mix deps.get && mix run --no-halt

# Terminal 2: Run basic client (starts stdio server as subprocess)
cd client_example_1 && mix deps.get && mix run run.exs

# Terminal 3: Run advanced client
cd client_example_2 && mix deps.get && mix run run.exs
```

## Key Reference Files in mcp_ex

- `lib/mcp/server/handler.ex` — Handler callback signatures
- `lib/mcp/server/tool_context.ex` — ToolContext API for async tools
- `lib/mcp/client.ex` — Full client API and start_link options
- `lib/mcp/transport/streamable_http/plug.ex` — Plug configuration for HTTP servers
- `conformance/server_handler.ex` — Most complete handler implementation
