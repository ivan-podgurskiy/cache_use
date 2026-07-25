defmodule CacheUseWeb.Router do
  use CacheUseWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CacheUseWeb do
    pipe_through :api

    get "/fetch", CacheController, :fetch
    get "/cache/size", CacheController, :size
  end
end
