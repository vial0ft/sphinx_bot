defmodule SphinxBot.Bot do
  @moduledoc """
  Bot handlers
  """
  require Logger
  require ExGram.Dsl.Keyboard

  alias ExGram.Model

  @waiting_answer_duration 60 * 1000
  @bot :sphinx_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("time")
  command("riddle")
  command("help", description: "Print the bot's help")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context), do: answer(context, "Hi!")
  def handle({:command, :help, _msg}, context), do: answer(context, "Here is your help:")
  def handle({:command, :time, _msg}, context) do
    symbols = GenServer.call(:riddle_clock, :symbols)
    time =
      Time.utc_now()
      |> Riddles.Clock.Format.convert_time(symbols)
      |> Riddles.Clock.Format.wrap_code()
    answer(context, time, parse_mode: "MarkdownV2")
  end

  def handle({:command, :riddle, msg},context) do
    extract_chat_user(msg)
    |> generate_riddle_for_user(context)
  end

  def handle({:callback_query, callback_query}, _context) do
    {chat, user} = extract_chat_user(callback_query)
    case Riddles.Store.get("#{chat.id}_#{user.id}") do
      {:ok, {riddle, pid}} ->
        right? =
          callback_query
          |> extract_callback_data
          |> Riddles.Checker.check_answer(riddle)
        send(pid, {:answer, right?})
      {:error, why} ->
        IO.puts("ignore: #{why}")
        :ignore
    end
  end

  def handle(
    {:message,
     %Model.Message{chat: chat, new_chat_members: new_users_list}},
    context
  ) when is_list(new_users_list) do
    IO.puts("#{inspect(chat, pretty: true)} new: #{inspect(new_users_list, pretty: true)}")
    Enum.each(new_users_list, fn user -> generate_riddle_for_user({chat, user}, context)  end)
  end

  def handle({:text, _ , msg}, _) do
    IO.puts(":txt")
   # IO.puts(inspect(txt))
    cu = {chat, user} = extract_chat_user(msg)
    IO.puts(inspect(cu))
    case Riddles.Store.get(riddle_store_key(cu)) do
      {:ok, _} -> SphinxBot.Background.ban_user(chat.id, user.id)
      _ -> :do_nothing
    end
  end

  #default handler
  def handle(msg, _cnt), do: IO.puts("Unknown message " <> inspect(msg, pretty: true))

  @spec generate_riddle_for_user({Model.Chat.t(), Model.User.t()},ExGram.Cnt.t()) :: any
  defp generate_riddle_for_user({chat,user} = ch_u, context) do
    %{text: text, opts: opts} = riddle = Riddles.Generator.generate_riddle()
    formatted_text =
      text
      |> SphinxBot.Format.add_user(user)
      |> SphinxBot.Format.add_sec_time_limit(60)

    resp = answer(
      context,
      formatted_text,
      parse_mode: "MarkdownV2",
      reply_markup: prepare_opts(opts)
    ) |> send_answers
    pid =
      extract_response_msg_id(resp)
      |> SphinxBot.Background.waiting_for_answer({chat.id, user.id}, @waiting_answer_duration)

    riddle_store_key(ch_u)
    |> Riddles.Store.add({riddle, pid})
  end

  defp prepare_opts(opts) do
    opts
    |> Enum.map(&riddle_opt_2_btn/1)
    |> Enum.split(2)
    |> as_list
    |> create_inline
  end

  defp as_list({f,s}) do
    [f,s]
  end

  defp riddle_opt_2_btn(%{text: text, right?: right?}) do
    %{text: text, callback_data: to_string(right?)}
  end

  defp extract_chat_user(some_request) do
    with {:ok, chat} <- extract_chat(some_request),
         {:ok, user} <- extract_user(some_request)  do
    	{chat, user}
    end
  end

  defp extract_callback_data(callback) do
    callback.data
  end

  @spec extract_response_msg_id(ExGram.Cnt.t()) :: integer()
  defp extract_response_msg_id(%ExGram.Cnt{responses: [ok: msg]}) do
    msg.message_id
  end

  @spec riddle_store_key({Model.Chat.t(), Model.User.t()}) :: bitstring()
  defp riddle_store_key({chat, user}), do: "#{chat.id}_#{user.id}"
end
