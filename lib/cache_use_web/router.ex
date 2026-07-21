defmodule CacheUseWeb.Router do
  use CacheUseWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CacheUseWeb do
    pipe_through :api
  end

end
