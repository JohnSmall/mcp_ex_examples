# MCP Ex Examples — Implementation Plan

See the top-level README.md for the overview and quick start instructions.

## Phases

1. **Scaffolding & Documentation** — Directory structure, CLAUDE.md, README, docs
2. **server_example_1** — Stdio weather/calculator server (sync tools, resources)
3. **server_example_2** — HTTP knowledge base server (async tools, prompts, templates, logging)
4. **client_example_1** — Basic cross-connect client (both transports)
5. **client_example_2** — Advanced client (sampling, pagination, notification handling)
6. **Integration Testing** — Compile all, run end-to-end, polish

## Acceptance Criteria

- All 4 projects compile with zero warnings
- server_example_2 starts and responds to curl requests
- client_example_1 connects to both servers and demonstrates basic operations
- client_example_2 demonstrates the full sampling roundtrip via analyze_note
- Each project has a README with usage instructions
