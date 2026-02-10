# Architecture

## Connection Topology

```
┌─────────────────┐       stdio        ┌─────────────────────┐
│ client_example_1 │──────────────────►│  server_example_1    │
│ (basic client)   │                   │  (weather/calculator)│
│                  │       HTTP        │  Port: stdio         │
│                  │──────────────┐    └─────────────────────┘
└─────────────────┘              │
                                 ▼
┌─────────────────┐       ┌─────────────────────┐
│ client_example_2 │──┐   │  server_example_2    │
│ (advanced client)│  │   │  (knowledge base)    │
│                  │  │   │  Port: 8080          │
└─────────────────┘  │   └─────────────────────┘
         │           │              ▲
         │   stdio   │     HTTP     │
         └───────────┼──────────────┘
                     │
         ┌───────────▼──────────────┐
         │  server_example_1        │
         │  (2nd instance, via      │
         │   subprocess)            │
         └──────────────────────────┘
```

## Capability Matrix

### server_example_1 (Stdio)

| Callback | Feature |
|----------|---------|
| `init/1` | Stateless `%{}` |
| `handle_list_tools/2` | `get_weather`, `calculate` |
| `handle_call_tool/3` | Sync execution (3-arity) |
| `handle_list_resources/2` | `config://app` |
| `handle_read_resource/2` | Returns JSON config |

### server_example_2 (HTTP)

| Callback | Feature |
|----------|---------|
| `init/1` | State with log_level |
| `handle_list_tools/2` | `search_notes`, `create_note`, `analyze_note`, `tag_note` |
| `handle_call_tool/4` | Async execution (4-arity with ToolContext) |
| `handle_list_resources/2` | Dynamic list from KnowledgeBase agent |
| `handle_read_resource/2` | Fetch note by `kb://notes/{id}` URI |
| `handle_list_resource_templates/2` | `kb://notes/{noteId}` template |
| `handle_list_prompts/2` | `summarize`, `ask_question`, `draft_note` |
| `handle_get_prompt/3` | Returns prompt messages with note context |
| `handle_set_log_level/2` | Stores level in state |

## Transport Details

### Stdio Transport
- Messages: newline-delimited JSON-RPC 2.0
- Server started with `MCP.Transport.Stdio, mode: :server`
- Client launches server as subprocess via `command` + `args`

### HTTP Transport (Streamable HTTP)
- Server: Plug + Bandit on `http://localhost:8080/mcp`
- Client: `MCP.Transport.StreamableHTTP.Client` with `url` option
- Supports SSE streaming for async tool notifications
- Session management via `MCP-Session-Id` header

## Sampling Roundtrip Data Flow

When client_example_2 calls `analyze_note` on server_example_2:

```
1. Client ──POST──► Server: tools/call "analyze_note"
2. Server starts async tool execution
3. Server ──SSE───► Client: notifications/message (log)
4. Server ──SSE───► Client: notifications/progress (0/3)
5. Server ──SSE───► Client: sampling/createMessage (request)
6. Client ──POST──► Server: sampling response
7. Server ──SSE───► Client: notifications/progress (3/3)
8. Server ──SSE───► Client: tools/call response (final result)
```
