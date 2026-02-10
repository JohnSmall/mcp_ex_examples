# Client Example 1 — Basic Cross-Connect

A basic MCP client that connects to both example servers, demonstrating transport flexibility.

## Connections

- **server_example_1** (stdio) — launched as a subprocess
- **server_example_2** (HTTP) — must be running on `localhost:8080`

## Prerequisites

```bash
# Fetch deps for server_example_1 (needed for subprocess launch)
cd ../server_example_1 && mix deps.get && mix compile

# Start server_example_2 in a separate terminal
cd ../server_example_2 && mix deps.get && mix run --no-halt
```

## Usage

```bash
mix deps.get
mix run run.exs
```

## Demo Flow

1. **Stdio Server**: Connect → list tools → call `get_weather` → call `calculate` → list/read resources → close
2. **HTTP Server**: Connect → list tools → search notes → list resources → list prompts → get prompt → list resource templates → close
