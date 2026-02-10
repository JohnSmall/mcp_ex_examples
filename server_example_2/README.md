# Server Example 2 — HTTP Knowledge Base

An MCP server running over Streamable HTTP transport with async tool execution, prompts, resource templates, and logging.

## Features

- **Tools**: `search_notes`, `create_note`, `analyze_note` (async with sampling), `tag_note`
- **Resources**: Dynamic notes from the knowledge base (`kb://notes/{id}`)
- **Resource Templates**: `kb://notes/{noteId}`
- **Prompts**: `summarize`, `ask_question`, `draft_note`
- **Logging**: `handle_set_log_level` support
- **Transport**: Streamable HTTP on port 8080
- **Execution**: Asynchronous (4-arity `handle_call_tool` with ToolContext)

## Usage

```bash
mix deps.get
mix run --no-halt
```

The server listens at `http://localhost:8080/mcp`.

## Tools

### search_notes

Search notes by query string matching titles, content, and tags.

### create_note

Create a new note with title, content, and optional tags.

### analyze_note

Demonstrates the full async/bidirectional flow:
1. Sends log messages via `ToolContext.log`
2. Sends progress notifications via `ToolContext.send_progress`
3. Requests LLM analysis via `ToolContext.request_sampling` (server-to-client)
4. Returns the combined analysis result

### tag_note

Add tags to an existing note.

## Testing with curl

```bash
# Initialize
curl -s -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```
