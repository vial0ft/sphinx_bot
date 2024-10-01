defmodule SphinxBot.WaitingUserAnswer do
	use GenServer

  @spec start_link(%{riddle_msg_id: non_neg_integer(),
                     chat_id: non_neg_integer(),
                     user_id: non_neg_integer(),
                     timeout: non_neg_integer()
                    }):: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @spec user_answer(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, boolean()) :: :ok
  def user_answer(pid, right_answer?) do
    GenServer.cast(pid, {:user_answer, right_answer?})
  end

  @impl true
  @spec init(%{:timeout => non_neg_integer(), optional(any()) => any()}) ::
          {:ok, %{:timeout => non_neg_integer(), optional(any()) => any()}}
  def init(%{timeout: timeout} = initial_state) do
    timer(timeout)
    {:ok, initial_state}
  end

  @impl true
  def handle_cast(
    {:user_answer, right_answer?},
    %{user_id: user_id,
      chat_id: chat_id,
      riddle_msg_id: msg_id} = state) do
  	if not right_answer? do
      SphinxBot.Background.ban_user(chat_id, user_id)
    end
    SphinxBot.Background.delete_message(chat_id, msg_id)
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(
    :timeout,
    %{user_id: user_id,
      chat_id: chat_id,
      riddle_msg_id: msg_id} = state) do
  	SphinxBot.Background.ban_user(chat_id, user_id)
    SphinxBot.Background.delete_message(chat_id, msg_id)
    {:stop, :normal, state}
  end

  @spec timer(non_neg_integer()) :: reference()
  defp timer(timeout) do
    Process.send_after(self(), :timeout, timeout)
  end
end
