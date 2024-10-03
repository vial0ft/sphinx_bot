defmodule Riddles.Clock.Riddle do
  alias Riddles.Clock.Format
  alias Riddles.Clock.RiddleMessage

  @moduledoc """
  Clock riddle
  """

  use GenServer

  @spec start_link(map()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(symbols) do
    GenServer.start_link(__MODULE__, symbols, name: __MODULE__)
  end

  def one_riddle() do
    GenServer.call(__MODULE__, :riddle)
  end

  # Server

  @impl true
  @spec init(map()) :: :ignore | {:error, any()} | {:ok, pid()}
  def init(symbols) do
    {:ok, symbols}
  end

  @impl true
  def handle_call(:symbols, _, symbols) do
    {:reply, symbols, symbols}
  end

  @impl true
  def handle_call(:riddle, _from, symbols) do
    riddle_time = Time.utc_now() |> Time.add(Enum.random(-59..59), :minute)
    additional_minutes = Enum.random(-59..59)
    answer = Time.add(riddle_time, additional_minutes, :minute)

    riddle_opts =
      [%{time: answer, right?: true} | gen_riddle_fake_opts(3)]
      |> Enum.map(&riddle_opt_format/1)
      |> Enum.shuffle()

    {:reply,
     %{
       type: :clock,
       answer: answer,
       text: RiddleMessage.riddle_text(riddle_time, additional_minutes, symbols),
       opts: riddle_opts
     }, symbols}
  end

  defp gen_riddle_fake_opts(n) do
    fake = for _ <- 1..n, do: gen_riddle_time_opt()
    Enum.map(fake, fn fake_answer -> %{time: fake_answer, right?: false} end)
  end

  defp riddle_opt_format(%{time: time, right?: right?}) do
    %{text: Format.time2str(time), right?: right?}
  end

  defp gen_riddle_time_opt do
    {:ok, time} = Time.new(Enum.random(0..23), Enum.random(0..59), 0)
    time
  end
end
