defmodule Riddles.Generator do
  @moduledoc """
  Generate Riddle
  """

  defp type_of_riddle do
    case Enum.random(1..1) do
      1 -> :clock
      _ -> :default
    end
  end

  def generate_riddle do
    case type_of_riddle() do
      :clock -> Riddles.Clock.Riddle.one_riddle()
      _ -> Riddles.Clock.Riddle.one_riddle()
    end
  end
end
