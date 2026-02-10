# The Application module starts the HTTP server and KnowledgeBase automatically.
# This script just keeps the process alive.
IO.puts("MCP Knowledge Base server running at http://localhost:8080/mcp")
IO.puts("Press Ctrl+C to stop.")
Process.sleep(:infinity)
