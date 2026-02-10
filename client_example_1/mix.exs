defmodule ClientExample1.MixProject do
  use Mix.Project

  def project do
    [
      app: :client_example_1,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Use path dep for local development; switch to hex for production:
      # {:mcp_ex, "~> 0.2"}
      {:mcp_ex, path: "../../mcp_ex"},
      {:req, "~> 0.5"},
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.5"}
    ]
  end
end
