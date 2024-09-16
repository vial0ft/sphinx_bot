defmodule Riddles.Generator do
  @moduledoc """
  Generate Riddle
  """

  defp type_of_riddle do
    :clock
  end

  def generate_riddle do
    case type_of_riddle() do
      :clock -> Riddles.Clock.Riddle.one_riddle()
      _ -> Riddles.Clock.Riddle.one_riddle()
    end
    
  end
end
