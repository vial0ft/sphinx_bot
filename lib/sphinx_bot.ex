defmodule SphinxBot do
  @moduledoc """
  Documentation for `SphinxBot`.
  """

  def init_tabe do
    :ets.new(:clock, [:set, :public, :named_table])
  end

  @doc """
  Hello world.
  """
  def hello do
    Map.put(%{}, :qwe, 1)
    with {:ok, symbols_str} <- File.read("resources/clock_symbols.json"),
         {:ok, symbols} <- Jason.decode(symbols_str)
      do
      :ets.insert(:clock, {"symbols", symbols})
      else
        err -> err
    end
  end
end
