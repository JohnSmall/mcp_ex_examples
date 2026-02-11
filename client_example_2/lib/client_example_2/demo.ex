defmodule ClientExample2.Demo do
  @moduledoc """
  Advanced client demonstration with sampling, pagination, and notification handling.
  """

  def run do
    IO.puts("=" |> String.duplicate(60))
    IO.puts("  MCP Client Example 2 — Advanced Client Demo")
    IO.puts("=" |> String.duplicate(60))

    # Part 1: Connect to server_example_1 via stdio with callbacks
    IO.puts("\n--- Part 1: Stdio Server with Pagination ---\n")
    demo_stdio_with_pagination()

    # Part 2: Connect to server_example_2 via HTTP with full callbacks
    IO.puts("\n--- Part 2: HTTP Server with Sampling Roundtrip ---\n")
    demo_http_with_sampling()

    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("  Demo complete!")
    IO.puts(String.duplicate("=", 60))
  end

  defp demo_stdio_with_pagination do
    server_path = Path.expand("../server_example_1", File.cwd!())

    IO.puts("Starting stdio client with full callbacks...")

    {:ok, client} =
      MCP.Client.start_link(
        transport:
          {MCP.Transport.Stdio,
           command: "/bin/sh",
           args: ["-c", "cd #{server_path} && mix run --no-halt 2>/dev/null"]},
        client_info: %{name: "client-example-2", version: "0.1.0"},
        on_roots_list: fn _params ->
          IO.puts("  [roots] Server requested roots list")

          {:ok,
           %{
             "roots" => [
               %{"uri" => "file:///workspace/mcp_ex_examples", "name" => "MCP Examples"}
             ]
           }}
        end,
        notification_handler: &handle_notification("stdio", &1, &2)
      )

    IO.puts("Connecting...")
    {:ok, info} = MCP.Client.connect(client)
    IO.puts("Connected to #{info.server_info.name} v#{info.server_info.version}")

    # Pagination demo — list_all_tools
    IO.puts("\nPagination: list_all_tools:")
    {:ok, all_tools} = MCP.Client.list_all_tools(client)
    IO.puts("  Found #{length(all_tools)} tools (across all pages)")

    for tool <- all_tools do
      IO.puts("  - #{tool["name"]}: #{tool["description"]}")
    end

    # Pagination demo — list_all_resources
    IO.puts("\nPagination: list_all_resources:")
    {:ok, all_resources} = MCP.Client.list_all_resources(client)
    IO.puts("  Found #{length(all_resources)} resources")

    for resource <- all_resources do
      IO.puts("  - #{resource["name"]} (#{resource["uri"]})")
    end

    # Call tools
    IO.puts("\nCalling get_weather(city: \"London\"):")
    {:ok, result} = MCP.Client.call_tool(client, "get_weather", %{"city" => "London"})
    IO.puts("  Result: #{hd(result["content"])["text"]}")

    IO.puts("\nCalling calculate(expression: \"100 / 3\"):")
    {:ok, result} = MCP.Client.call_tool(client, "calculate", %{"expression" => "100 / 3"})
    IO.puts("  Result: #{hd(result["content"])["text"]}")

    IO.puts("\nClosing stdio connection...")
    MCP.Client.close(client)
    IO.puts("Done.")
  end

  defp demo_http_with_sampling do
    IO.puts("Starting HTTP client with sampling callback...")

    {:ok, client} =
      MCP.Client.start_link(
        transport:
          {MCP.Transport.StreamableHTTP.Client, url: "http://localhost:8080/mcp"},
        client_info: %{name: "client-example-2", version: "0.1.0"},
        on_sampling: &ClientExample2.SamplingHandler.handle/1,
        on_roots_list: fn _params ->
          IO.puts("  [roots] Server requested roots list")

          {:ok,
           %{
             "roots" => [
               %{"uri" => "file:///workspace/mcp_ex_examples", "name" => "MCP Examples"}
             ]
           }}
        end,
        on_elicitation: fn params ->
          IO.puts("  [elicitation] Server requested user input: #{params["message"]}")
          {:ok, %{"action" => "accept", "content" => %{"confirmed" => true}}}
        end,
        notification_handler: &handle_notification("http", &1, &2)
      )

    IO.puts("Connecting...")
    {:ok, info} = MCP.Client.connect(client)
    IO.puts("Connected to #{info.server_info.name} v#{info.server_info.version}")

    # Pagination demo
    IO.puts("\nPagination: list_all_tools:")
    {:ok, all_tools} = MCP.Client.list_all_tools(client)
    IO.puts("  Found #{length(all_tools)} tools")

    for tool <- all_tools do
      IO.puts("  - #{tool["name"]}: #{tool["description"]}")
    end

    IO.puts("\nPagination: list_all_resources:")
    {:ok, all_resources} = MCP.Client.list_all_resources(client)
    IO.puts("  Found #{length(all_resources)} resources")

    for resource <- all_resources do
      IO.puts("  - #{resource["name"]} (#{resource["uri"]})")
    end

    IO.puts("\nPagination: list_all_prompts:")
    {:ok, all_prompts} = MCP.Client.list_all_prompts(client)
    IO.puts("  Found #{length(all_prompts)} prompts")

    for prompt <- all_prompts do
      IO.puts("  - #{prompt["name"]}: #{prompt["description"]}")
    end

    # Sampling roundtrip demo
    IO.puts("\n--- Sampling Roundtrip Demo ---")
    IO.puts("Calling analyze_note(noteId: \"note-1\") — triggers server-to-client sampling:")
    IO.puts("  (The server will request LLM sampling, and our callback will respond)")

    {:ok, result} =
      MCP.Client.call_tool(client, "analyze_note", %{"noteId" => "note-1"},
        timeout: 60_000
      )

    IO.puts("\n  Final result:")
    IO.puts("  #{hd(result["content"])["text"]}")

    # Create a note
    IO.puts("\nCreating a new note:")

    {:ok, result} =
      MCP.Client.call_tool(client, "create_note", %{
        "title" => "Client Example Notes",
        "content" => "Created by client_example_2 during demo run.",
        "tags" => ["demo", "client"]
      })

    IO.puts("  #{hd(result["content"])["text"]}")

    # Verify with search
    IO.puts("\nSearching for the new note:")
    {:ok, result} = MCP.Client.call_tool(client, "search_notes", %{"query" => "demo"})
    text = hd(result["content"])["text"]
    IO.puts("  #{String.slice(text, 0, 200)}...")

    IO.puts("\nClosing HTTP connection...")
    MCP.Client.close(client)
    IO.puts("Done.")
  end

  defp handle_notification(transport, "notifications/progress", params) do
    progress = params["progress"]
    total = params["total"]
    bar = if total, do: " (#{progress}/#{total})", else: " (#{progress})"
    IO.puts("  [#{transport} progress]#{bar}")
  end

  defp handle_notification(transport, "notifications/message", params) do
    level = params["level"]
    data = params["data"]
    IO.puts("  [#{transport} log/#{level}] #{data}")
  end

  defp handle_notification(transport, method, params) do
    IO.puts("  [#{transport} notification] #{method}: #{inspect(params)}")
  end
end
