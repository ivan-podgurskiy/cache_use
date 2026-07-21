defmodule CacheUse.Upstream.Counter do
  @moduledoc false

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def next do
    Agent.get_and_update(__MODULE__, fn sequence ->
      next_sequence = sequence + 1
      {next_sequence, next_sequence}
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> 0 end)
  end
end
