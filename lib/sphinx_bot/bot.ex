defmodule SphinxBot.Bot do
  @moduledoc """
  Bot handlers
  """
  require Logger

  require ExGram.Dsl.Keyboard

  @waiting_answer_duration 60 * 1000
  @bot :sphinx_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("hello")
  command("time")
  command("riddle")
  command("keyboard")
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
    |> Riddles.Clock.Format.wrap_code()
    answer(context, time, parse_mode: "MarkdownV2")
  end

  def handle({:command, :riddle, msg},context) do
    {:ok, chat} = extract_chat(msg)
    {:ok, user} = extract_user(msg)
    riddle = Riddles.Generator.generate_riddle()
    %{text: text, opts: opts} = riddle
    spawn(fn -> :timer.sleep(1000); answer(context, "hi!") end)
    resp =  answer(
      context,
      text,
      parse_mode: "MarkdownV2",
      reply_markup: opts |> Enum.map(&riddle_opt_2_btn/1) |> Enum.split(2) |> as_list |> create_inline
    ) |> send_answers

     msg_id = extract_response_msg_id(resp)
     _pid = SphinxBot.Background.waiting_for_answer(msg_id, {chat.id, user.id}, @waiting_answer_duration)
  end

  def handle({:command, :help, _msg}, context) do
    # IO.puts(context)
    answer(context, "Here is your help:")
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

  defp as_list({f,s}) do
    [f,s]
  end

  defp riddle_opt_2_btn(%{text: text, right?: right?}) do
    %{text: text, callback_data: to_string(right?)}
  end

  defp extract_response_msg_id(%ExGram.Cnt{responses: [ok: msg]}) do
    msg.message_id
  end
end
