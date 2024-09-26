defmodule Riddles.Store do
  @moduledoc """
  Riddle storage
  """
require Logger

  @default_ttl_sec 60
  @clean_up_period 5 * 60 * 1000
  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @spec add(bitstring(), {any(), pid()}) :: any()
  def add(key, {_riddle, _waiting_pid} = value) do
    GenServer.call(__MODULE__, {:add, key, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end


  # Server

  @impl true
  def init(riddle_table_name) do
    :ets.new(riddle_table_name, [:set, :public, :named_table])
    schedule_clean()
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

  defp check_expiration({_, {_riddle, pid} = riddle_value}) do
    cond do
      !Process.alive?(pid) -> {:error, "Process isn't alive"}
      :else -> {:ok, riddle_value}
    end
  end 

  defp check_expiration({_, {_riddle, pid} = riddle_value, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> {:ok, riddle_value}
      !Process.alive?(pid) -> {:error, "Process isn't alive"}
      :else -> {:error, "Expired"}
    end
  end

  @impl true
  def handle_info(:clean, %{:table => table} = state) do
    Logger.debug("run cleanup")
    ms = :os.system_time(:seconds) |> ms4moment()
    delete = :ets.select_delete(table, ms)
    Logger.debug("delete count: #{delete}")
    schedule_clean()
    {:noreply, state}
  end

  defp ms4moment(moment) do
    [{
      {:"$1", :"$2",:"$3"},
      [
        {:>=, {:const, moment}, :"$3"}
      ],
      [true],
      }]
  end

  defp schedule_clean() do
    Process.send_after(self(), :clean, @clean_up_period)
  end
end

