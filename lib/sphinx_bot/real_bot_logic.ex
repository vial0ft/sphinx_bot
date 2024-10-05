defmodule SphinxBot.RealBotLogic do
  @behaviour GenServer

  require Logger

  alias ExGram.Model
  alias SphinxBot.Format
  alias SphinxBot.Background

  @spec start_link(map()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  # API

  @spec time() :: bitstring()
  def time() do
    GenServer.call(__MODULE__, :time)
  end

  @type chat_user :: {ExGram.Model.Chat.t(), ExGram.Model.User.t()}
  @type send_func :: (chat_user, text :: bitstring(), any() -> integer())

  @spec riddle(chat_user, send_func) :: any()
  def riddle(ch_u, send_riddle_func) do
    GenServer.call(__MODULE__, {:riddle, ch_u, send_riddle_func})
  end

  @spec new_user(chat_user, send_func) :: any()
  def new_user(chat_user, send_riddle_func) do
    GenServer.call(__MODULE__, {:new_chat_member, chat_user, send_riddle_func})
  end

  def left_user(chat_user) do
    GenServer.cast(__MODULE__, {:left_chat_member, chat_user})
  end

  @spec user_answer(chat_user, any()) :: any()
  def user_answer(chat_user, data) do
    GenServer.cast(__MODULE__, {:callback, chat_user, data})
  end

  @spec message(chat_user) :: any()
  def message(chat_user) do
    GenServer.cast(__MODULE__, {:text, chat_user})
  end

  # Server

  @impl true
  @spec init(any()) :: {:ok, any()}
  def init(state) do
    {:ok, state}
  end

  @impl true
  @spec handle_call(:time, any(), map()) :: {:reply, bitstring(), map()}
  def handle_call(:time, _from, state) do
    symbols = GenServer.call(Riddles.Clock.Riddle, :symbols)

    time =
      Time.utc_now()
      |> Riddles.Clock.Format.convert_time(symbols)
      |> Riddles.Clock.Format.wrap_code()

    {:reply, time, state}
  end

  @impl true
  @spec handle_call({:riddle, chat_user, send_func}, any(), map()) :: {:reply, any(), map()}
  def handle_call({:riddle, {chat, user} = ch_u, send_riddle_func}, _from, state) do

    %{text: text, opts: opts} = riddle = Riddles.Generator.generate_riddle()

    formatted_text =
      text
      |> Format.add_user(user)
      |> Format.add_sec_time_limit(div(state.timeout, 1000))

    msg_id = send_riddle_func.(ch_u, formatted_text, opts)
    {:ok, pid} = Background.waiting_for_answer(msg_id, {chat.id, user.id}, state)

    storage_key = riddle_store_key(ch_u) |> Riddles.Store.add({riddle, pid})
    {:reply, storage_key, state}
  end

  @impl true
  @spec handle_call({:new_chat_member, chat_user, send_func}, any(), map()) ::
          {:reply, :ignore, map()} | {:reply, any(), map()}
  def handle_call({:new_chat_member, chat_user, send_riddle_func}, from, state) do
    Infra.VisitLogger.log({:new_user, chat_user})
    handle_call({:riddle, chat_user, send_riddle_func}, from, state)
  end

  @impl true
  def handle_cast({:left_chat_member, chat_user}, state) do
    Infra.VisitLogger.log({:left, chat_user})

    case Riddles.Store.get(riddle_store_key(chat_user)) do
      {:ok, {_, pid}} -> SphinxBot.WaitingUserAnswer.stop_waiting(pid)
      _ -> :do_nothing
    end

    {:noreply, state}
  end

  @impl true
  @spec handle_cast({:text, chat_user}, map()) :: {:noreply, map()}
  def handle_cast({:text, {chat, user} = chat_user}, state) do
    case Riddles.Store.get(riddle_store_key(chat_user)) do
      {:ok, {_, pid}} ->
        SphinxBot.WaitingUserAnswer.stop_waiting(pid)
        SphinxBot.Background.ban_user(chat.id, user.id)
      _ -> :do_nothing
    end

    {:noreply, state}
  end

  @impl true
  @spec handle_cast({:callback, chat_user, any()}, map()) :: {:noreply, map()}
  def handle_cast({:callback, ch_u, data}, state) do
    case Riddles.Store.get(riddle_store_key(ch_u)) do
      {:ok, {riddle, pid}} ->
        right? = Riddles.Checker.check_answer(data, riddle)
        SphinxBot.WaitingUserAnswer.user_answer(pid, right?)

      {:error, why} ->
        Logger.error("ignore callback: #{why}")
        :ignore
    end

    {:noreply, state}
  end

  @spec riddle_store_key({Model.Chat.t(), Model.User.t()}) :: bitstring()
  def riddle_store_key({chat, user}), do: "#{chat.id}_#{user.id}"
end
