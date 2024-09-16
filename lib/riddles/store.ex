defmodule Riddles.Store do
  @moduledoc """
  Riddle storage
  """

  @default_ttl_sec 60
  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: :riddle_storage)
  end

  @spec add(bitstring(), {any(), pid()}) :: any()
  def add(key, {_riddle, _waiting_pid} = value) do
    GenServer.call(:riddle_storage, {:add, key, value})
  end

  def get(key) do
    GenServer.call(:riddle_storage, {:get, key})
  end


  # Server

  @impl true
  def init(riddle_table_name) do
    :ets.new(riddle_table_name, [:set, :public, :named_table])
    {:ok, %{table: riddle_table_name}}
  end

  @impl true
  def handle_call({:add, key, riddle_and_pid}, from, state) do
    handle_call({:add, key, riddle_and_pid, @default_ttl_sec}, from , state)
  end

  @impl true
  def handle_call({:add, key, riddle_and_pid, ttl}, _from, %{:table => table} = state) do
  	:ets.insert(table, {key, riddle_and_pid, :os.system_time(:seconds) + ttl})
    {:reply, {:ok, key}, state}
  end

  @impl true
  def handle_call({:get, key}, _from,  %{:table => table} = state) do
    res = case :ets.lookup(table, key) do
            [found] -> check_expiration(found)
            [] -> {:error, "Not found"}
          end
    {:reply, res , state}
  end

  defp check_expiration ({_, {riddle, pid}, expiration}) do
    cond do
      expiration > :os.system_time() -> {:ok, riddle}
      !Process.alive?(pid) -> {:error, "Process isn't alive"}
      :else -> {:error, "Expired"}
    end
  end

  @impl true
  def handle_cast(:clean, state) do
  	{:noreply, state}
  end
end

