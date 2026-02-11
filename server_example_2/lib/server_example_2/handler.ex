defmodule ServerExample2.Handler do
  @moduledoc """
  MCP handler for the HTTP knowledge base server.

  Implements async tool execution (4-arity with ToolContext), prompts,
  resource templates, and logging.
  """

  @behaviour MCP.Server.Handler

  alias MCP.Server.ToolContext
  alias ServerExample2.KnowledgeBase

  @impl true
  def init(_opts) do
    {:ok, %{log_level: "info"}}
  end

  # --- Tools ---

  @impl true
  def handle_list_tools(_cursor, state) do
    tools = [
      %{
        "name" => "search_notes",
        "description" => "Search the knowledge base for notes matching a query",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "query" => %{"type" => "string", "description" => "Search query"}
          },
          "required" => ["query"]
        }
      },
      %{
        "name" => "create_note",
        "description" => "Create a new note in the knowledge base",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "title" => %{"type" => "string", "description" => "Note title"},
            "content" => %{"type" => "string", "description" => "Note content"},
            "tags" => %{
              "type" => "array",
              "items" => %{"type" => "string"},
              "description" => "Tags for the note"
            }
          },
          "required" => ["title", "content"]
        }
      },
      %{
        "name" => "analyze_note",
        "description" =>
          "Analyze a note using LLM sampling — demonstrates async execution with ToolContext",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "noteId" => %{"type" => "string", "description" => "ID of the note to analyze"}
          },
          "required" => ["noteId"]
        }
      },
      %{
        "name" => "tag_note",
        "description" => "Add tags to an existing note",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "noteId" => %{"type" => "string", "description" => "ID of the note to tag"},
            "tags" => %{
              "type" => "array",
              "items" => %{"type" => "string"},
              "description" => "Tags to add"
            }
          },
          "required" => ["noteId", "tags"]
        }
      }
    ]

    {:ok, tools, nil, state}
  end

  @impl true
  def handle_call_tool("search_notes", %{"query" => query}, ctx, state) do
    ToolContext.log(ctx, "info", "Searching for: #{query}")
    results = KnowledgeBase.search_notes(query)

    text =
      case results do
        [] ->
          "No notes found matching '#{query}'."

        notes ->
          header = "Found #{length(notes)} note(s):\n\n"

          details =
            Enum.map_join(notes, "\n\n", fn note ->
              "## #{note.title} (#{note.id})\n#{note.content}\nTags: #{Enum.join(note.tags, ", ")}"
            end)

          header <> details
      end

    {:ok, [%{"type" => "text", "text" => text}], state}
  end

  def handle_call_tool("create_note", args, ctx, state) do
    ToolContext.log(ctx, "info", "Creating note: #{args["title"]}")
    note = KnowledgeBase.create_note(args)

    {:ok,
     [
       %{
         "type" => "text",
         "text" =>
           "Created note '#{note.title}' with ID: #{note.id}\nTags: #{Enum.join(note.tags, ", ")}"
       }
     ], state}
  end

  def handle_call_tool("analyze_note", %{"noteId" => note_id}, ctx, state) do
    ToolContext.log(ctx, "info", "Starting analysis of note #{note_id}")
    ToolContext.send_progress(ctx, 0, 3)

    case KnowledgeBase.get_note(note_id) do
      nil ->
        {:error, -32_002, "Note not found: #{note_id}", state}

      note ->
        ToolContext.log(ctx, "info", "Found note: #{note.title}")
        ToolContext.send_progress(ctx, 1, 3)

        # Request LLM sampling from the client — the key async/bidirectional feature
        ToolContext.log(ctx, "info", "Requesting LLM analysis via sampling...")

        # The server's default request_timeout (30s) will reply {:error, :timeout}
        # before the GenServer.call's default 60s timeout, so this returns normally.
        sampling_result =
          ToolContext.request_sampling(ctx, %{
            "messages" => [
              %{
                "role" => "user",
                "content" => %{
                  "type" => "text",
                  "text" =>
                    "Please analyze the following note and provide a brief summary:\n\n" <>
                      "Title: #{note.title}\nContent: #{note.content}\nTags: #{Enum.join(note.tags, ", ")}"
                }
              }
            ],
            "maxTokens" => 200
          })

        ToolContext.send_progress(ctx, 2, 3)

        analysis =
          case sampling_result do
            {:ok, result} ->
              get_in(result, ["content", "text"]) || "Analysis received: #{inspect(result)}"

            {:error, reason} ->
              "Sampling unavailable (#{inspect(reason)}), using basic analysis:\n" <>
                "Note '#{note.title}' has #{length(note.tags)} tags and " <>
                "#{String.length(note.content)} characters of content."
          end

        ToolContext.send_progress(ctx, 3, 3)
        ToolContext.log(ctx, "info", "Analysis complete for note #{note_id}")

        {:ok,
         [
           %{
             "type" => "text",
             "text" => "Analysis of '#{note.title}':\n\n#{analysis}"
           }
         ], state}
    end
  end

  def handle_call_tool("tag_note", %{"noteId" => note_id, "tags" => tags}, ctx, state) do
    ToolContext.log(ctx, "info", "Tagging note #{note_id} with: #{inspect(tags)}")

    case KnowledgeBase.tag_note(note_id, tags) do
      :not_found ->
        {:error, -32_002, "Note not found: #{note_id}", state}

      note ->
        {:ok,
         [
           %{
             "type" => "text",
             "text" =>
               "Updated tags for '#{note.title}': #{Enum.join(note.tags, ", ")}"
           }
         ], state}
    end
  end

  def handle_call_tool(name, _args, _ctx, state) do
    {:error, -32_601, "Unknown tool: #{name}", state}
  end

  # --- Resources ---

  @impl true
  def handle_list_resources(_cursor, state) do
    notes = KnowledgeBase.list_notes()

    resources =
      Enum.map(notes, fn note ->
        %{
          "uri" => "kb://notes/#{note.id}",
          "name" => note.title,
          "mimeType" => "application/json"
        }
      end)

    {:ok, resources, nil, state}
  end

  @impl true
  def handle_read_resource("kb://notes/" <> note_id, state) do
    case KnowledgeBase.get_note(note_id) do
      nil ->
        {:error, -32_002, "Note not found: #{note_id}", state}

      note ->
        json =
          Jason.encode!(%{
            id: note.id,
            title: note.title,
            content: note.content,
            tags: note.tags
          })

        {:ok,
         [%{"uri" => "kb://notes/#{note_id}", "mimeType" => "application/json", "text" => json}],
         state}
    end
  end

  def handle_read_resource(uri, state) do
    {:error, -32_002, "Resource not found: #{uri}", state}
  end

  # --- Resource Templates ---

  @impl true
  def handle_list_resource_templates(_cursor, state) do
    templates = [
      %{
        "uriTemplate" => "kb://notes/{noteId}",
        "name" => "Knowledge Base Note",
        "description" => "Access a specific note by ID",
        "mimeType" => "application/json"
      }
    ]

    {:ok, templates, nil, state}
  end

  # --- Prompts ---

  @impl true
  def handle_list_prompts(_cursor, state) do
    prompts = [
      %{
        "name" => "summarize",
        "description" => "Summarize a note from the knowledge base",
        "arguments" => [
          %{
            "name" => "noteId",
            "description" => "ID of the note to summarize",
            "required" => true
          }
        ]
      },
      %{
        "name" => "ask_question",
        "description" => "Ask a question about the knowledge base",
        "arguments" => [
          %{
            "name" => "question",
            "description" => "The question to ask",
            "required" => true
          }
        ]
      },
      %{
        "name" => "draft_note",
        "description" => "Draft a new note on a given topic",
        "arguments" => [
          %{
            "name" => "topic",
            "description" => "Topic for the new note",
            "required" => true
          }
        ]
      }
    ]

    {:ok, prompts, nil, state}
  end

  @impl true
  def handle_get_prompt("summarize", args, state) do
    note_id = Map.get(args || %{}, "noteId", "unknown")

    note_context =
      case KnowledgeBase.get_note(note_id) do
        nil -> "Note #{note_id} not found."
        note -> "Title: #{note.title}\nContent: #{note.content}\nTags: #{Enum.join(note.tags, ", ")}"
      end

    {:ok,
     %{
       "description" => "Summarize a knowledge base note",
       "messages" => [
         %{
           "role" => "user",
           "content" => %{
             "type" => "text",
             "text" => "Please provide a concise summary of the following note:\n\n#{note_context}"
           }
         }
       ]
     }, state}
  end

  def handle_get_prompt("ask_question", args, state) do
    question = Map.get(args || %{}, "question", "")

    notes = KnowledgeBase.list_notes()

    context =
      Enum.map_join(notes, "\n\n", fn note ->
        "## #{note.title}\n#{note.content}"
      end)

    {:ok,
     %{
       "description" => "Ask a question about the knowledge base",
       "messages" => [
         %{
           "role" => "user",
           "content" => %{
             "type" => "text",
             "text" =>
               "Based on the following knowledge base:\n\n#{context}\n\nQuestion: #{question}"
           }
         }
       ]
     }, state}
  end

  def handle_get_prompt("draft_note", args, state) do
    topic = Map.get(args || %{}, "topic", "")

    {:ok,
     %{
       "description" => "Draft a new note",
       "messages" => [
         %{
           "role" => "user",
           "content" => %{
             "type" => "text",
             "text" =>
               "Please draft a knowledge base note on the following topic: #{topic}\n\n" <>
                 "Format it with a clear title, detailed content, and suggest relevant tags."
           }
         }
       ]
     }, state}
  end

  def handle_get_prompt(name, _args, state) do
    {:error, -32_601, "Unknown prompt: #{name}", state}
  end

  # --- Logging ---

  @impl true
  def handle_set_log_level(level, state) do
    {:ok, %{state | log_level: level}}
  end
end
