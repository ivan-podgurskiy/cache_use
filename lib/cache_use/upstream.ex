defmodule CacheUse.Upstream do
  @moduledoc """
  Local upstream simulator used by the Phoenix cache sandbox.
  """

  alias CacheUse.Upstream.Counter

  @default_ttl 60

  def fetch(%Cache.Request{path: path, params: params}) do
    sequence = Counter.next()
    ttl = ttl_from(params)

    %Cache.Response{
      ttl: ttl,
      body: %{
        path: path,
        params: params,
        sequence: sequence,
        generated_at_ms: System.system_time(:millisecond)
      }
    }
  end

  defp ttl_from(%{"ttl" => ttl}) do
    case Integer.parse(to_string(ttl)) do
      {value, ""} when value > 0 -> value
      _ -> @default_ttl
    end
  end

  defp ttl_from(_params), do: @default_ttl
end
