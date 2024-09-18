defmodule Riddles.Clock.RiddleTest do
	alias Riddles.Clock.Riddle
  use ExUnit.Case
  doctest Riddles.Clock.Riddle

describe "Clock.Riddle" do
    test("Generate clock riddle") do
  	  %{
        type: type,
        answer: answer,
        text: text,
        opts: opts
      } = Riddle.one_riddle()
      assert type == :clock
      assert String.length(text) > 0
      assert length(opts) > 1
      assert answer != nil
    end
  end
end
