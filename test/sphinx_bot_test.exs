defmodule SphinxBotTest do
  use ExUnit.Case
  doctest SphinxBot

  test "greets the world" do
    assert SphinxBot.hello() == :world
  end
end
