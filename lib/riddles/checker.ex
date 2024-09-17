defmodule Riddles.Checker do
  @moduledoc """
  Check that an answer is correct
  """
  # for now 'data' may be only true | false
  @spec check_answer(bitstring(), any()) :: boolean()
  def check_answer(data, _riddle) do
    String.to_atom(data)
  end
end
