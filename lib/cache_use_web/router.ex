defmodule CacheUseWeb.Router do
  use CacheUseWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CacheUseWeb do
    pipe_through :api

    get "/fetch", CacheController, :fetch
    post "/cache/clear", CacheController, :clear
    delete "/cache", CacheController, :invalidate
    get "/cache/size", CacheController, :size
  end
end
