defmodule ServerExample1.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {MCP.Server,
       transport: {MCP.Transport.Stdio, mode: :server},
       handler: {ServerExample1.Handler, []},
       server_info: %{name: "server-example-1", version: "0.1.0"}}
    ]

    opts = [strategy: :one_for_one, name: ServerExample1.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
