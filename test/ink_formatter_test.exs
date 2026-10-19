defmodule StathamLogger.InkFormatterTest do
  use ExUnit.Case, async: true

  alias StathamLogger.InkFormatter

  @timestamp {{2026, 10, 19}, {10, 0, 0, 0}}

  defp msg(message) do
    :info
    |> InkFormatter.format_event(message, @timestamp, %{}, %{})
    |> Jason.encode!()
    |> Jason.decode!()
    |> Map.fetch!("msg")
  end

  test "formats a binary message" do
    assert msg("hello") == "hello"
  end

  test "formats a charlist with codepoints above 255" do
    assert msg(~c"crash in π → 😀") == "crash in π → 😀"
  end

  test "formats a charlist with latin-1 codepoints as UTF-8" do
    assert msg([?c, ?a, ?f, 233]) == "café"
  end

  test "formats nested chardata mixing binaries and codepoints" do
    assert msg(["crash: ", [?π, ?α], " ", ~c"é"]) == "crash: πα é"
  end
end
