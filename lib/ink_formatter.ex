defmodule StathamLogger.InkFormatter do
  @moduledoc """
  Re-use ink format
  """

  @skipped_metadata_keys [:erl_level, :gl, :time, :sentry]

  def format_event(level, message, timestamp, sanitized_metadata, _raw_metadata) do
    message
    |> base_map(timestamp, level)
    |> Map.merge(process_metadata(sanitized_metadata))
  end

  defp process_metadata(sanitized_metadata) do
    sanitized_metadata
    |> Map.drop(@skipped_metadata_keys)
    |> rename_metadata_fields
    |> Enum.into(%{})
  end

  defp rename_metadata_fields(metadata) do
    metadata
    |> Enum.map(fn
      {:pid, value} -> {:erlang_pid, value}
      other -> other
    end)
  end

  defp base_map(message, timestamp, level) when is_binary(message) do
    %{
      name: "elixirs",
      pid: System.pid() |> String.to_integer(),
      hostname: hostname(),
      msg: message,
      time: formatted_timestamp(timestamp),
      level: level(level, :bunyan),
      v: 0
    }
  end

  defp base_map(message, timestamp, level) when is_list(message) do
    base_map(IO.iodata_to_binary(message), timestamp, level)
  end

  defp formatted_timestamp({date, {hours, minutes, seconds, milliseconds}}) do
    {date, {hours, minutes, seconds}}
    |> NaiveDateTime.from_erl!({milliseconds * 1000, 3})
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp hostname do
    with {:ok, hostname} <- :inet.gethostname(), do: List.to_string(hostname)
  end

  # https://github.com/trentm/node-bunyan#levels
  defp level(level, :bunyan) do
    case level do
      :debug -> 20
      :info -> 30
      :warn -> 40
      :error -> 50
    end
  end

  # http://erlang.org/documentation/doc-10.0/lib/kernel-6.0/doc/html/logger_chapter.html#log-level
  defp level(level, :rfc5424) do
    case level do
      :debug -> 7
      :info -> 6
      :warn -> 4
      :error -> 3
    end
  end
end
