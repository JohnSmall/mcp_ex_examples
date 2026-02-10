# Testing Procedures

## Per-Example Verification

### server_example_1 (Stdio)

```bash
cd server_example_1
mix deps.get
mix compile
# Should compile with zero warnings
```

The stdio server is designed to be used as a subprocess by clients. It reads JSON-RPC from stdin and writes to stdout. Manual testing via piping is possible but the clients provide the best verification.

### server_example_2 (HTTP)

```bash
cd server_example_2
mix deps.get
mix compile
mix run --no-halt &

# Initialize
curl -s -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

# Should return session ID in MCP-Session-Id header and server capabilities
```

### client_example_1 (Basic)

```bash
# Requires server_example_2 running on port 8080
cd client_example_1
mix deps.get
mix run run.exs
```

Expected output:
- Connects to server_example_1 via stdio
- Lists tools: get_weather, calculate
- Calls get_weather and calculate
- Lists and reads config://app resource
- Connects to server_example_2 via HTTP
- Lists tools: search_notes, create_note, analyze_note, tag_note
- Searches notes, lists resources, prompts, resource templates
- Closes both connections

### client_example_2 (Advanced)

```bash
# Requires server_example_2 running on port 8080
cd client_example_2
mix deps.get
mix run run.exs
```

Expected output:
- Connects to both servers with full callbacks
- Pagination demo using list_all_tools, list_all_resources, list_all_prompts
- Sampling roundtrip: calls analyze_note, sampling callback fires, result returns
- Progress notifications displayed
- Log messages displayed
- Closes both connections

## End-to-End Test Sequence

```bash
# Terminal 1: Start HTTP server
cd /workspace/mcp_ex_examples/server_example_2
mix deps.get && mix run --no-halt

# Terminal 2: Run basic client
cd /workspace/mcp_ex_examples/client_example_1
mix deps.get && mix run run.exs

# Terminal 3: Run advanced client
cd /workspace/mcp_ex_examples/client_example_2
mix deps.get && mix run run.exs
```

## Troubleshooting

- **"Could not start server_example_1 subprocess"** — Ensure server_example_1 deps are fetched: `cd server_example_1 && mix deps.get`
- **"Connection refused on port 8080"** — Ensure server_example_2 is running: `cd server_example_2 && mix run --no-halt`
- **Compilation errors** — Run `mix deps.get` in each project directory
- **Timeout errors** — The stdio subprocess may take a moment to start. Increase timeouts if needed.
