defmodule SphinxBot.Background do
  @moduledoc """
  Delete Messages, ban users
  """
  require Logger
  use GenServer
  require ExGram

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, any()}
  def init(state) do
    {:ok, state}
  end

  @spec delete_message(any(), any()) :: :ok
  def delete_message(chat_id, msg_id) do
    GenServer.cast(__MODULE__, {:delete_msgs, {chat_id, [msg_id]}})
  end

  @spec ban_user(integer(), integer()) :: :ok
  @spec ban_user(integer(), integer(), boolean()) :: :ok
  def ban_user(chat_id, user_id, revoke_messages \\ true) do
    GenServer.cast(__MODULE__, {:ban, {chat_id, user_id, revoke_messages}})
  end

  @spec waiting_for_answer(
          non_neg_integer(),
          {non_neg_integer(), non_neg_integer()},
          map()
        ) :: :ignore | {:error, any()} | {:ok, pid()}
  def waiting_for_answer(msg_id, {chat_id, user_id}, opts \\ %{}) do
    %{riddle_msg_id: msg_id, chat_id: chat_id, user_id: user_id}
    |> Map.merge(Map.take(opts, [:timeout]))
    |> SphinxBot.WaitingUserAnswer.start_link()
  end

  @impl true
  @spec handle_cast({:delete_msgs, {integer(), list(integer())}}, any()) :: {:noreply, any()}
  def handle_cast({:delete_msgs, {chat_id, msg_ids}}, state) do
    ExGram.delete_messages(chat_id, msg_ids)
    {:noreply, state}
  end

  @impl true
  @spec handle_cast({:ban, {integer(), integer(), boolean()}}, any()) :: {:noreply, any()}
  def handle_cast({:ban, {chat_id, user_id, revoke_messages}}, state) do
    Logger.info("chat_id #{chat_id}, ban #{user_id}")
    ExGram.ban_chat_member(chat_id, user_id, revoke_messages: revoke_messages)
    {:noreply, state}
  end
end
