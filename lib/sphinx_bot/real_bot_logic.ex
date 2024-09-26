defmodule SphinxBot.RealBotLogic do
	@behaviour SphinxBot.BotLogic

  require Logger

  @waiting_answer_duration 60 * 1000

  alias ExGram.Model
  alias SphinxBot.Format
  alias SphinxBot.Background

  @impl true
  def handle(:time) do
    symbols = GenServer.call(Riddles.Clock.Riddle, :symbols)

    Time.utc_now()
    |> Riddles.Clock.Format.convert_time(symbols)
    |> Riddles.Clock.Format.wrap_code()
  end

  @impl true
  def handle(:riddle, {chat, user} = ch_u , send_riddle_func) do
    %{text: text, opts: opts} = riddle = Riddles.Generator.generate_riddle()
    formatted_text =
      text
      |> Format.add_user(user)
      |> Format.add_sec_time_limit(60)

    msg_id = send_riddle_func.(ch_u, formatted_text,  opts)
    pid = Background.waiting_for_answer(msg_id, {chat.id, user.id}, @waiting_answer_duration)

    riddle_store_key(ch_u)
    |> Riddles.Store.add({riddle, pid})
  end

  @impl true
  def handle(:callback, ch_u, data) do
    case Riddles.Store.get(riddle_store_key(ch_u)) do
      {:ok, {riddle, pid}} ->
        right? = Riddles.Checker.check_answer(data, riddle)
        send(pid, {:answer, right?})
      {:error, why} ->
        Logger.error("ignore: #{why}")
        :ignore
    end
  end

  @impl true
  def handle(:new_chat_member, chat_user, send_riddle_func) do
    handle(:riddle, chat_user, send_riddle_func)
  end


  @impl true
  @spec handle(:text, {ExGram.Model.Chat.t(), ExGram.Model.User.t()}) :: :do_nothing | :ok
  def handle(:text, {chat, user} = chat_user) do
    case Riddles.Store.get(riddle_store_key(chat_user)) do
      {:ok, _} -> SphinxBot.Background.ban_user(chat.id, user.id)
      _ -> :do_nothing
    end
  end

  @spec riddle_store_key({Model.Chat.t(), Model.User.t()}) :: bitstring()
  def riddle_store_key({chat, user}), do: "#{chat.id}_#{user.id}"

end
