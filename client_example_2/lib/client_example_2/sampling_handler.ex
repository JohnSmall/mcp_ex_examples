defmodule ClientExample2.SamplingHandler do
  @moduledoc """
  Handles `sampling/createMessage` requests from the server.

  When the server's `analyze_note` tool calls `ToolContext.request_sampling`,
  this callback fires on the client side, demonstrating the full bidirectional flow.
  """

  def handle(params) do
    messages = Map.get(params, "messages", [])
    max_tokens = Map.get(params, "maxTokens", 100)

    IO.puts("  [sampling] Server requested LLM sampling:")
    IO.puts("  [sampling]   Messages: #{length(messages)}")
    IO.puts("  [sampling]   Max tokens: #{max_tokens}")

    # Extract the user's prompt for display
    last_message = List.last(messages)

    if last_message do
      content = Map.get(last_message, "content", %{})
      text = if is_map(content), do: Map.get(content, "text", ""), else: ""
      IO.puts("  [sampling]   Prompt preview: #{String.slice(text, 0, 100)}...")
    end

    # Return a mock LLM response — in production this would call an actual LLM
    {:ok,
     %{
       "role" => "assistant",
       "content" => %{
         "type" => "text",
         "text" =>
           "This is a mock LLM analysis response. The note covers important concepts " <>
             "and is well-structured with relevant tags. Key themes include technical " <>
             "documentation and knowledge management."
       },
       "model" => "mock-model-v1",
       "stopReason" => "endTurn"
     }}
  end
end
