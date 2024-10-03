defmodule Riddles.Clock.RiddleMessageTest do
  alias Riddles.Clock.RiddleMessage
  use ExUnit.Case
  doctest Riddles.Clock.RiddleMessage

  setup_all do
    symbols = SphinxBot.Application.init_riddle_data()
    {:ok, symbols}
  end

  test("riddle text with positive delta", symbols) do
    expected =
      """
      Сейчас на часах:
      ```
      ### ###   ### ###
      # #   # #   # # #
      # #   #    ## # #
      # #   # #   # # #
      ###   #   ### ###
      ```
      Ответь: сколько времени будет через 15 мин?
      """

    {:ok, time} = Time.new(7, 30, 0)
    assert RiddleMessage.riddle_text(time, 15, symbols) == expected
  end

  test("riddle text with negative delta", symbols) do
    expected =
      """
      Сейчас на часах:
      ```
      ### ###   ### ###
      # #   # #   # # #
      # #   #    ## # #
      # #   # #   # # #
      ###   #   ### ###
      ```
      Ответь: сколько времени было 15 мин назад?
      """

    {:ok, time} = Time.new(7, 30, 0)
    assert RiddleMessage.riddle_text(time, -15, symbols) == expected
  end
end
