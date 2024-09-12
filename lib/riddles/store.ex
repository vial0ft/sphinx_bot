defmodule Riddles.Store do
  @moduledoc """
  Riddle storage
  """

  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: :riddle_storage)
  end

  def add(key, riddle) do
    GenServer.call(:riddle_storage, {:add, key, riddle})
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
  def handle_call({:add, key, riddle}, _from, %{:table => table} = state) do
  	:ets.insert(table, {key, riddle})
    {:reply, {:ok, key}, state}
  end

  @impl true
  def handle_call({:get, key}, _from,  %{:table => table} = state) do
    {:reply, :ets.lookup(table, key), state}
  end
end

