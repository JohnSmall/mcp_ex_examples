defmodule ClientExample1.Demo do
  @moduledoc """
  Sequential demonstration of basic MCP client operations.
  """

  def run do
    IO.puts("=" |> String.duplicate(60))
    IO.puts("  MCP Client Example 1 — Basic Cross-Connect Demo")
    IO.puts("=" |> String.duplicate(60))

    # Part 1: Connect to server_example_1 via stdio
    IO.puts("\n--- Part 1: Stdio Server (Weather/Calculator) ---\n")
    demo_stdio_server()

    # Part 2: Connect to server_example_2 via HTTP
    IO.puts("\n--- Part 2: HTTP Server (Knowledge Base) ---\n")
    demo_http_server()

    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("  Demo complete!")
    IO.puts(String.duplicate("=", 60))
  end

  defp demo_stdio_server do
    server_path = Path.expand("../server_example_1", File.cwd!())

    IO.puts("Starting stdio client (launching server_example_1 as subprocess)...")

    {:ok, client} =
      MCP.Client.start_link(
        transport:
          {MCP.Transport.Stdio,
           command: "/bin/sh",
           args: ["-c", "cd #{server_path} && mix run --no-halt"]},
        client_info: %{name: "client-example-1", version: "0.1.0"},
        notification_handler: fn method, params ->
          IO.puts("  [stdio notification] #{method}: #{inspect(params)}")
        end
      )

    IO.puts("Connecting...")
    {:ok, info} = MCP.Client.connect(client)
    IO.puts("Connected to #{info.server_info.name} v#{info.server_info.version}")

    # List tools
    IO.puts("\nListing tools:")
    {:ok, result} = MCP.Client.list_tools(client)

    for tool <- result["tools"] do
      IO.puts("  - #{tool["name"]}: #{tool["description"]}")
    end

    # Call get_weather
    IO.puts("\nCalling get_weather(city: \"Tokyo\"):")
    {:ok, result} = MCP.Client.call_tool(client, "get_weather", %{"city" => "Tokyo"})
    IO.puts("  Result: #{hd(result["content"])["text"]}")

    # Call calculate
    IO.puts("\nCalling calculate(expression: \"2 + 3 * 4\"):")
    {:ok, result} = MCP.Client.call_tool(client, "calculate", %{"expression" => "2 + 3 * 4"})
    IO.puts("  Result: #{hd(result["content"])["text"]}")

    # List resources
    IO.puts("\nListing resources:")
    {:ok, result} = MCP.Client.list_resources(client)

    for resource <- result["resources"] do
      IO.puts("  - #{resource["name"]} (#{resource["uri"]})")
    end

    # Read resource
    IO.puts("\nReading config://app:")
    {:ok, result} = MCP.Client.read_resource(client, "config://app")
    IO.puts("  Content: #{hd(result["contents"])["text"]}")

    IO.puts("\nClosing stdio connection...")
    MCP.Client.close(client)
    IO.puts("Done.")
  end

  defp demo_http_server do
    IO.puts("Starting HTTP client (connecting to localhost:8080)...")

    {:ok, client} =
      MCP.Client.start_link(
        transport:
          {MCP.Transport.StreamableHTTP.Client, url: "http://localhost:8080/mcp"},
        client_info: %{name: "client-example-1", version: "0.1.0"},
        notification_handler: fn method, params ->
          IO.puts("  [http notification] #{method}: #{inspect(params)}")
        end
      )

    IO.puts("Connecting...")
    {:ok, info} = MCP.Client.connect(client)
    IO.puts("Connected to #{info.server_info.name} v#{info.server_info.version}")

    # List tools
    IO.puts("\nListing tools:")
    {:ok, result} = MCP.Client.list_tools(client)

    for tool <- result["tools"] do
      IO.puts("  - #{tool["name"]}: #{tool["description"]}")
    end

    # Search notes
    IO.puts("\nCalling search_notes(query: \"elixir\"):")
    {:ok, result} = MCP.Client.call_tool(client, "search_notes", %{"query" => "elixir"})
    text = hd(result["content"])["text"]
    IO.puts("  Result: #{String.slice(text, 0, 200)}...")

    # List resources
    IO.puts("\nListing resources:")
    {:ok, result} = MCP.Client.list_resources(client)

    for resource <- result["resources"] do
      IO.puts("  - #{resource["name"]} (#{resource["uri"]})")
    end

    # List prompts
    IO.puts("\nListing prompts:")
    {:ok, result} = MCP.Client.list_prompts(client)

    for prompt <- result["prompts"] do
      IO.puts("  - #{prompt["name"]}: #{prompt["description"]}")
    end

    # Get a prompt
    IO.puts("\nGetting prompt 'summarize' for note-1:")

    {:ok, result} =
      MCP.Client.get_prompt(client, "summarize", %{"noteId" => "note-1"})

    first_msg = hd(result["messages"])
    IO.puts("  Role: #{first_msg["role"]}")
    IO.puts("  Text: #{String.slice(first_msg["content"]["text"], 0, 150)}...")

    # List resource templates
    IO.puts("\nListing resource templates:")
    {:ok, result} = MCP.Client.list_resource_templates(client)

    for template <- result["resourceTemplates"] do
      IO.puts("  - #{template["name"]}: #{template["uriTemplate"]}")
    end

    IO.puts("\nClosing HTTP connection...")
    MCP.Client.close(client)
    IO.puts("Done.")
  end
end
