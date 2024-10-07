defmodule SphinxBot.Bot do
  @moduledoc """
  Bot handlers
  """
  require Logger
  require ExGram.Dsl.Keyboard

  alias SphinxBot.ConfigManager
  alias SphinxBot.RealBotLogic
  alias ExGram.Model

  @bot :sphinx_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("time")
  command("riddle")
  command("health", description: "Some of system info")
  command("help", description: "Print the bot's help")
  command("halt")
  command("config")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context), do: answer(context, "Hi!")
  def handle({:command, :help, _msg}, context), do: answer(context, "Here is your help:")
  def handle({:command, :health, msg}, context) do
    {ch, u} = extract_chat_user(msg)
    if is_user_admin(ch, u) do
      answer(context, to_string(health()))
    end
  end

  def handle({:command , :halt, msg}, _ctx) do
    Logger.debug("halt call")
    {ch, u} = extract_chat_user(msg)
    with {:ok, status} <- user_status(ch, u),
         {:ok, halted} <- change_halt({ch.id, status}) do
    	msg = if halted, do: "💤", else: "⏰"
      if halted, do: RealBotLogic.pause(ch.id)
      ExGram.send_message(ch.id, msg)
    else
      err -> Logger.debug(inspect(err))
    end
  end

  def handle({:command , :config, msg}, _ctx) do
  	{ch, u} = extract_chat_user(msg)
    with {:ok, status}  <- user_status(ch, u) do
      config =
        ConfigManager.get_current_state({ch.id, status})
        |> Enum.map_join("\n", fn {key, val} -> "'#{key}' : '#{val}'" end)
      ExGram.send_message(ch.id, "{\n#{config}\n}")
    else
      err -> Logger.debug(err)
    end
  end

  def handle({:command, :time, _msg}, context) do
    time = RealBotLogic.time()
    answer(context, time, parse_mode: "MarkdownV2")
  end

  def handle({:command, :riddle, msg}, context) do
    chat_user = extract_chat_user(msg)
    RealBotLogic.riddle(chat_user, riddle_sender(context))
  end



  def handle({:callback_query, callback_query}, _context) do
    chat_user = extract_chat_user(callback_query)
    data = extract_callback_data(callback_query)
    RealBotLogic.user_answer(chat_user, data)
  end

  def handle(
        {:message, %Model.Message{chat: chat, new_chat_members: new_users_list}},
        context
      )
      when is_list(new_users_list) do
    Enum.each(
      new_users_list,
      fn user ->
        if user.id != context.bot_info.id do
          RealBotLogic.new_user({chat, user}, riddle_sender(context))
        end
      end
    )
  end

  def handle(
        {:message, %Model.Message{chat: chat, left_chat_member: left_user}},
        context
      )
      when not is_nil(left_user) do
    if left_user.id != context.bot_info.id, do: RealBotLogic.left_user({chat, left_user})
  end

  def handle({:text, _, msg}, _cnt) do
        Logger.debug("msg: #{inspect(msg)}")
        {ch, u} = ch_u = extract_chat_user(msg)
        case ExGram.get_chat_member(ch.id, u.id) do
          {:ok, member} ->
            Logger.debug(inspect(member, pretty: true))
            RealBotLogic.message(ch_u)
          _ -> :ignore
        end
        Logger.debug(inspect(ExGram.get_chat_member(ch.id, u.id)))
        RealBotLogic.message(ch_u)
  end

  # default handler
  def handle(msg, _cnt) do
    # Logger.info("ctx" <> inspect(cnt, pretty: true))
    Logger.info("Unknown message " <> inspect(msg, pretty: true))
  end

  defp change_halt(ch_us) do
    case ConfigManager.change_state("halt", ch_us) do
      :ignore -> {:error, :ignore}
      halted -> {:ok, halted}
    end
  end

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

  defp as_list({f, s}) do
    [f, s]
  end

  defp riddle_opt_2_btn(%{text: text, right?: right?}) do
    %{text: text, callback_data: to_string(right?)}
  end

  defp extract_chat_user(some_request) do
    with {:ok, chat} <- extract_chat(some_request),
         {:ok, user} <- extract_user(some_request) do
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

  defp user_status(ch, u) do
    with {:ok, m} <- ExGram.get_chat_member(ch.id, u.id) do
      {:ok, m.status}
    else
      _ -> {:error, "Cant get status of user_id #{inspect(u)} in chat #{inspect(ch)}"}
    end
  end

  defp is_user_admin(ch, u) do
      case user_status(ch, u) do
        {:ok,"creator"} -> true
        {:ok, "administrator"} -> true
        _ -> false
      end
  end

  defp health() do
    :erlang.memory()
    |> Enum.map_join("\n", fn {key, val} -> ~s{"#{key}": #{val}} end)
  end
end
