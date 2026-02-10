# MCP Ex Examples

Four example projects demonstrating the [mcp_ex](../mcp_ex/) library — an Elixir implementation of the [Model Context Protocol](https://modelcontextprotocol.io/) (MCP).

## Examples

| Project | Transport | Description |
|---------|-----------|-------------|
| [server_example_1](server_example_1/) | Stdio | Weather/calculator server with sync tools and resources |
| [server_example_2](server_example_2/) | HTTP | Knowledge base server with async tools, prompts, resource templates, and logging |
| [client_example_1](client_example_1/) | Both | Basic client connecting to both servers — lists and calls tools, reads resources |
| [client_example_2](client_example_2/) | Both | Advanced client with sampling callbacks, pagination helpers, and notification handling |

## Connection Topology

Both clients connect to both servers, demonstrating transport flexibility:

```
client_example_1 ──stdio──► server_example_1 (weather/calculator)
client_example_1 ──HTTP───► server_example_2 (knowledge base)
client_example_2 ──stdio──► server_example_1 (weather/calculator)
client_example_2 ──HTTP───► server_example_2 (knowledge base)
```

## Quick Start

```bash
# 1. Start the HTTP server (Terminal 1)
cd server_example_2
mix deps.get && mix run --no-halt

# 2. Run the basic client demo (Terminal 2)
cd client_example_1
mix deps.get && mix run run.exs

# 3. Run the advanced client demo (Terminal 3)
cd client_example_2
mix deps.get && mix run run.exs
```

The stdio server (server_example_1) is launched automatically as a subprocess by the clients.

## Prerequisites

- Elixir ~> 1.17
- The `mcp_ex` library at `../mcp_ex` (path dependency)

## Capability Matrix

| Feature | server_example_1 | server_example_2 |
|---------|:-:|:-:|
| Tools (sync) | get_weather, calculate | — |
| Tools (async + ToolContext) | — | search_notes, create_note, analyze_note, tag_note |
| Resources | config://app | Dynamic (kb://notes/{id}) |
| Resource Templates | — | kb://notes/{noteId} |
| Prompts | — | summarize, ask_question, draft_note |
| Logging | — | Set log level |
| Sampling roundtrip | — | analyze_note triggers sampling |
| Progress notifications | — | analyze_note sends progress |
