defmodule Riddles.Clock.Riddle do
  @moduledoc """
  Clock riddle
  """

  use GenServer

  @spec start_link(map()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(symbols) do
    GenServer.start_link(__MODULE__, symbols, name: :riddle_clock)
  end

  def one_riddle() do
    GenServer.call(:riddle_clock, :riddle)
  end


  # Server

  @impl true
  @spec init(map()) :: :ignore | {:error, any()} | {:ok, pid()}
  def init(symbols) do
    {:ok, symbols}
  end

  def handle_call(:symbols, _from, state) do
  	{:reply, state, state}
  end

  @impl true
  def handle_call(:riddle, _from, symbols) do
    # riddle_time = Time.utc_now() |> Time.add(Enum.random(-59..59), :minute)
    # additional_minutes = Enum.random(-59..59)
    {:reply, "", symbols}
  end

end
