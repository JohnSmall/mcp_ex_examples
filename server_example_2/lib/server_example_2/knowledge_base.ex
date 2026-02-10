defmodule ServerExample2.KnowledgeBase do
  @moduledoc """
  In-memory knowledge base backed by an Agent.

  Stores notes with id, title, content, and tags.
  Seeded with sample notes about Elixir, MCP, and functional programming.
  """

  use Agent

  @seed_notes [
    %{
      id: "note-1",
      title: "Introduction to Elixir",
      content:
        "Elixir is a functional, concurrent programming language built on the Erlang VM (BEAM). " <>
          "It is designed for building scalable and maintainable applications with features like " <>
          "pattern matching, immutable data, and the actor model for concurrency.",
      tags: ["elixir", "programming", "beam"]
    },
    %{
      id: "note-2",
      title: "Model Context Protocol Overview",
      content:
        "MCP (Model Context Protocol) is an open protocol that enables standardized integration " <>
          "between LLM applications and external data sources. It uses JSON-RPC 2.0 over pluggable " <>
          "transports like stdio and Streamable HTTP.",
      tags: ["mcp", "protocol", "llm"]
    },
    %{
      id: "note-3",
      title: "Functional Programming Concepts",
      content:
        "Functional programming emphasizes immutability, pure functions, and declarative code. " <>
          "Key concepts include higher-order functions, pattern matching, recursion, and " <>
          "composition over inheritance.",
      tags: ["functional", "programming", "concepts"]
    },
    %{
      id: "note-4",
      title: "OTP and Supervision Trees",
      content:
        "OTP (Open Telecom Platform) provides a set of libraries and design principles for " <>
          "building concurrent, fault-tolerant systems. Supervision trees organize processes " <>
          "hierarchically, enabling automatic restart on failure.",
      tags: ["elixir", "otp", "concurrency"]
    }
  ]

  def start_link(_opts) do
    Agent.start_link(fn -> @seed_notes end, name: __MODULE__)
  end

  def list_notes do
    Agent.get(__MODULE__, & &1)
  end

  def get_note(id) do
    Agent.get(__MODULE__, fn notes ->
      Enum.find(notes, &(&1.id == id))
    end)
  end

  def create_note(attrs) do
    id = "note-#{System.unique_integer([:positive])}"

    note = %{
      id: id,
      title: Map.get(attrs, "title", "Untitled"),
      content: Map.get(attrs, "content", ""),
      tags: Map.get(attrs, "tags", [])
    }

    Agent.update(__MODULE__, fn notes -> notes ++ [note] end)
    note
  end

  def search_notes(query) do
    query_down = String.downcase(query)

    Agent.get(__MODULE__, fn notes ->
      Enum.filter(notes, fn note ->
        String.contains?(String.downcase(note.title), query_down) or
          String.contains?(String.downcase(note.content), query_down) or
          Enum.any?(note.tags, &String.contains?(String.downcase(&1), query_down))
      end)
    end)
  end

  def tag_note(id, new_tags) do
    Agent.get_and_update(__MODULE__, fn notes ->
      case Enum.find_index(notes, &(&1.id == id)) do
        nil ->
          {:not_found, notes}

        index ->
          note = Enum.at(notes, index)
          updated = %{note | tags: Enum.uniq(note.tags ++ new_tags)}
          {updated, List.replace_at(notes, index, updated)}
      end
    end)
  end
end
