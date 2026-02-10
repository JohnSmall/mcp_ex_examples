# Server Example 1 — Stdio Weather/Calculator

A simple MCP server running over stdio transport with sync tool execution and resources.

## Features

- **Tools**: `get_weather` (mock weather data), `calculate` (math expression evaluator)
- **Resources**: `config://app` (server configuration as JSON)
- **Transport**: Stdio (newline-delimited JSON-RPC)
- **Execution**: Synchronous (3-arity `handle_call_tool`)

## Usage

```bash
mix deps.get
mix run --no-halt
```

The server reads JSON-RPC messages from stdin and writes responses to stdout. It is designed to be launched as a subprocess by MCP clients.

## Tools

### get_weather

Returns mock weather data for a city.

```json
{"name": "get_weather", "arguments": {"city": "Tokyo"}}
```

Response: `"Weather in Tokyo: 72F, sunny"`

### calculate

Evaluates a math expression safely.

```json
{"name": "calculate", "arguments": {"expression": "2 + 3 * 4"}}
```

Response: `"14"`

## Resources

### config://app

Returns the server configuration as JSON.
