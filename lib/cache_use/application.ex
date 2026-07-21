defmodule CacheUse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CacheUseWeb.Endpoint,
      CacheUse.Upstream.Counter,
      {Cache.LRU, cap: 100, upstream: &CacheUse.Upstream.fetch/1, name: CacheUse.Cache}
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
