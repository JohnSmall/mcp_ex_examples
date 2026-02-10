defmodule ServerExample1.Handler do
  @moduledoc """
  MCP handler for the weather/calculator stdio server.

  Implements sync tool execution (3-arity) and resource reading.
  """

  @behaviour MCP.Server.Handler

  @impl true
  def init(_opts), do: {:ok, %{}}

  # --- Tools ---

  @impl true
  def handle_list_tools(_cursor, state) do
    tools = [
      %{
        "name" => "get_weather",
        "description" => "Get current weather for a city",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "city" => %{"type" => "string", "description" => "City name"}
          },
          "required" => ["city"]
        }
      },
      %{
        "name" => "calculate",
        "description" => "Evaluate a math expression",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "expression" => %{"type" => "string", "description" => "Math expression to evaluate"}
          },
          "required" => ["expression"]
        }
      }
    ]

    {:ok, tools, nil, state}
  end

  @impl true
  def handle_call_tool("get_weather", %{"city" => city}, state) do
    weather = mock_weather(city)

    {:ok,
     [
       %{
         "type" => "text",
         "text" => "Weather in #{city}: #{weather.temp}F, #{weather.condition}"
       }
     ], state}
  end

  def handle_call_tool("calculate", %{"expression" => expr}, state) do
    {result, _bindings} = Code.eval_string(expr)
    {:ok, [%{"type" => "text", "text" => "#{result}"}], state}
  rescue
    e ->
      {:error, -32_602, "Invalid expression: #{Exception.message(e)}", state}
  end

  def handle_call_tool(name, _args, state) do
    {:error, -32_601, "Unknown tool: #{name}", state}
  end

  # --- Resources ---

  @impl true
  def handle_list_resources(_cursor, state) do
    resources = [
      %{
        "uri" => "config://app",
        "name" => "App Configuration",
        "mimeType" => "application/json"
      }
    ]

    {:ok, resources, nil, state}
  end

  @impl true
  def handle_read_resource("config://app", state) do
    config =
      Jason.encode!(%{
        server: "server-example-1",
        version: "0.1.0",
        debug: false,
        features: ["weather", "calculator"]
      })

    {:ok, [%{"uri" => "config://app", "mimeType" => "application/json", "text" => config}], state}
  end

  def handle_read_resource(uri, state) do
    {:error, -32_002, "Resource not found: #{uri}", state}
  end

  # --- Private ---

  defp mock_weather(city) do
    weathers = %{
      "london" => %{temp: 55, condition: "cloudy"},
      "tokyo" => %{temp: 72, condition: "sunny"},
      "new york" => %{temp: 45, condition: "rainy"},
      "paris" => %{temp: 60, condition: "partly cloudy"},
      "sydney" => %{temp: 82, condition: "sunny"}
    }

    Map.get(weathers, String.downcase(city), %{temp: 68, condition: "clear"})
  end
end
