defmodule Riddles.Clock.Format do

  defp number_to_str_list(num) do
    Integer.to_string(num) |> String.pad_leading(2, "0") |> String.split("", trim: true)
  end

  defp clock_str_lines(clock_elems, symbols) do
    res =
    for line_idx <- 0..5 do
      Enum.join([Enum.at(clock_elems, 0) |> Enum.at(line_idx),
                 Enum.at(clock_elems, 1) |> Enum.at(line_idx),
                 Map.get(symbols, ":") |> Enum.at(line_idx),
                 Enum.at(clock_elems, 2) |> Enum.at(line_idx),
                 Enum.at(clock_elems, 3) |> Enum.at(line_idx),
                 "\n"], " ")
    end
    Enum.join(res)
  end

  @spec convert_time(Time.t(), map()) :: binary()
  def convert_time(%Time{hour: hour, minute: mins}, symbols) do
    h = number_to_str_list(hour)
    m = number_to_str_list(mins)
    clock_elems = Enum.concat([
      Enum.map(h, fn n -> Map.get(symbols, n) end),
      Enum.map(m, fn n -> Map.get(symbols, n) end)
    ])

    clock_str_lines(clock_elems, symbols)
  end

  def wrap_code(s) do
    "```\n#{s}```"
  end

  def time2str(%Time{hour: hour, minute: mins}) do
    "#{number_to_str_list(hour)}:#{number_to_str_list(mins)}"
  end
end
