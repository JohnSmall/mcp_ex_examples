# Client Example 2 — Advanced Client with Callbacks

An advanced MCP client demonstrating sampling callbacks, pagination helpers, notification handling, and the full bidirectional sampling roundtrip.

## Connections

- **server_example_1** (stdio) — launched as a subprocess
- **server_example_2** (HTTP) — must be running on `localhost:8080`

## Features

- **`on_sampling`**: Handles `sampling/createMessage` requests from the server (mock LLM responses)
- **`on_roots_list`**: Reports workspace roots to the server
- **`on_elicitation`**: Handles server user-input requests with mock acceptance
- **Pagination**: Uses `list_all_tools`, `list_all_resources`, `list_all_prompts`
- **Notification handling**: Progress bars for `notifications/progress`, log messages for `notifications/message`

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

1. **Stdio Server**: Connect with callbacks → pagination demo → call tools → close
2. **HTTP Server**: Connect with full callbacks → pagination demo → **sampling roundtrip** (analyze_note triggers server-to-client sampling) → create note → search → close

## Sampling Roundtrip

The key demonstration is calling `analyze_note` on server_example_2:

1. Client calls `analyze_note` tool
2. Server starts async tool execution
3. Server sends log messages and progress notifications
4. Server requests LLM sampling via `ToolContext.request_sampling`
5. Client's `on_sampling` callback fires (in `SamplingHandler`)
6. Mock LLM response flows back to server
7. Server completes the analysis and returns the result
