defmodule SphinxBot.Bot do
  @moduledoc """
  Bot handlers
  """
  require Logger
  require ExGram.Dsl.Keyboard

  alias ExGram.Model

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
    time = SphinxBot.RealBotLogic.time()
    answer(context, time, parse_mode: "MarkdownV2")
  end

  def handle({:command, :riddle, msg},context) do
    chat_user = extract_chat_user(msg)
    SphinxBot.RealBotLogic.riddle(chat_user, riddle_sender(context))
  end

  def handle({:callback_query, callback_query}, _context) do
    chat_user = extract_chat_user(callback_query)
    data = extract_callback_data(callback_query)
    SphinxBot.RealBotLogic.user_answer(chat_user, data)
  end

  def handle(
    {:message,
     %Model.Message{chat: chat, new_chat_members: new_users_list}},
    context) when is_list(new_users_list) do
    # Logger.info("#{inspect(chat, pretty: true)} new: #{inspect(new_users_list, pretty: true)}")
    Enum.each(
      new_users_list,
      fn user ->
        SphinxBot.RealBotLogic.new_user({chat, user}, riddle_sender(context))
      end)
  end

  def handle({:text, _ , msg}, _) do
    extract_chat_user(msg)
    |> SphinxBot.RealBotLogic.message()
  end

  #default handler
  def handle(msg, _cnt), do: Logger.info("Unknown message " <> inspect(msg, pretty: true))


  defp riddle_sender(ctx) do
    fn _ch_u, text, opts ->
        answer(
          ctx,
          text,
          parse_mode: "MarkdownV2",
          reply_markup: prepare_opts(opts)
        )
        |> send_answers
        |> extract_response_msg_id
    end
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
end
