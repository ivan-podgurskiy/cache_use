defmodule CacheUse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: CacheUse.PubSub},
      # Start a worker by calling: CacheUse.Worker.start_link(arg)
      # {CacheUse.Worker, arg},
      # Start to serve requests, typically the last entry
      CacheUseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CacheUse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CacheUseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
