defmodule Riddles.Clock.FormatTest do
  alias Riddles.Clock.Format
	use ExUnit.Case
  doctest Riddles.Clock.Format

  setup_all do
    symbols = SphinxBot.Application.init_riddle_data()
  	{:ok, symbols}
  end

  test("riddle as code") do
    assert Format.wrap_code("2 + 2 == 4") == "```\n2 + 2 == 4```"
  end

  test("time format") do
    {:ok, time } = Time.new(12,42,0)
    assert Format.time2str(time) == "12:42"
  end

  test("riddle clock", symbols) do
    expect =
      """
      ### ###   ### ###
      # #   # #   # # #
      # #   #    ## # #
      # #   # #   # # #
      ###   #   ### ###
      """
    {:ok, time } = Time.new(7,30,0)
    assert Format.convert_time(time,symbols) == expect
  end
end
