defmodule SphinxBot.Bot do
  @moduledoc """
  Bot handlers
  """

  @bot :sphinx_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("hello")
  command("time")
  command("riddle")
  command("help", description: "Print the bot's help")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, :hello, _msg}, context) do
    answer(context, "Hello!")
  end

  def handle({:command, :time, _msg}, context) do
    symbols = GenServer.call(:riddle_clock, :symbols)
    time = Time.utc_now()
    |> Riddles.Clock.Format.convert_time(symbols)
    |> wrap_code()
    answer(context, time, parse_mode: "MarkdownV2")
  end

  def handle({:command, :help, _msg}, context) do
   # IO.puts(context)
    answer(context, "Here is your help:")
  end

  def handle({:command, :riddle, _msg}, context) do
   # IO.puts(context)
    answer(context, "1 riddle")
  end


  def handle({:text, txt, msg}, context) do
    IO.puts(":txt")
    IO.puts(inspect(txt))
    IO.puts(inspect(msg))
    answer(context, txt)
  end


  def handle(msg, _cnt) do
    IO.puts("Unknown message " <> inspect(msg))
  end


  defp wrap_code(s) do
    "```#{s}```\n"
  end
end
