defmodule ServerExample2.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    plug_config =
      MCP.Transport.StreamableHTTP.Plug.init(
        server_mod: ServerExample2.Handler,
        server_opts: [
          server_info: %{name: "server-example-2", version: "0.1.0"}
        ]
      )

    children = [
      ServerExample2.KnowledgeBase,
      {Bandit,
       plug: {MCP.Transport.StreamableHTTP.Plug, plug_config},
       port: 8080,
       ip: {127, 0, 0, 1}}
    ]

    opts = [strategy: :one_for_one, name: ServerExample2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
