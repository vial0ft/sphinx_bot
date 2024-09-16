defmodule Riddles.Clock.RiddleMessage do

  alias Riddles.Clock.Format

  @spec how_nuch_time_part(integer()) :: bitstring()
  defp how_nuch_time_part(delta_minutes)  do
  	if delta_minutes < 0 do
      "было #{abs(delta_minutes)} мин назад"
    else
      "будет через #{delta_minutes} мин"
    end
  end

  @spec riddle_text(Time.t(), integer(), map()) :: bitstring()
  def riddle_text(riddle_time, delta_minutes, symbols) do
    how_much_time_question_part = how_nuch_time_part(delta_minutes)
	  clockStr = Format.convert_time(riddle_time, symbols)
    """
    Сейчас на часах:
    #{Format.wrap_code(clockStr)}
    Ответь: сколько времени #{how_much_time_question_part}?
    """
  end
end
