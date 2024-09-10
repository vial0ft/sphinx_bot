defmodule SphinxBot do
  @moduledoc """
  Documentation for `SphinxBot`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> SphinxBot.hello()
      :world

  """
  def hello do
    System.get_env("TELEGRAM_APITOKEN")
  end
end
