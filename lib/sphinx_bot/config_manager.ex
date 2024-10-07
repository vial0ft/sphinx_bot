defmodule SphinxBot.ConfigManager do
  alias SphinxBot.ConfigManager.ChatConfig
  use GenServer

  require Logger

  defguardp is_admin(status) when status == "administrator"
  defguardp is_creator(status) when status == "creator"

  defguard is_admin_or_creator(status) when is_admin(status) or is_creator(status)

  @spec start_link(map()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec get_current_state(any()) :: any()
  def get_current_state({chat_id, user_status})
  when is_admin_or_creator(user_status) do
    GenServer.call(__MODULE__, {:get_config, chat_id})
  end

  def get_current_state(_), do: :no_premissions

  defp change_state_p(k_v, chat_id) when is_list(k_v) do
    GenServer.call(__MODULE__, {:change, k_v, chat_id})
  end

  def change_state(k_v, {chat_id, user_status})
  when is_admin_or_creator(user_status) and is_tuple(k_v) do
    change_state_p(Tuple.to_list(k_v), chat_id)
  end

  def change_state(k_v,{chat_id, user_status})
  when is_admin_or_creator(user_status) do
    change_state_p([k_v], chat_id)
  end

  def change_state(_, _), do: :no_premissions

  @impl true
  @spec init(map()) :: {:ok, any()}
  def init(init_config) do
    :ets.new(__MODULE__, [:set, :public, :named_table])
    Enum.each(
      init_config,
      fn {chat_id, config} ->
        :ets.insert_new(__MODULE__, {chat_id, ChatConfig.new(config)})
      end
    )
    {:ok, %{}}
  end


  @impl true
  def handle_call({:get_config, chat_id},_from,state) do
    config = get_or_create_config(chat_id) |> ChatConfig.as_map
    {:reply, config, state}
  end

  @impl true
  def handle_call({:change, k_v, chat_id},_from, state) do
    with config <- get_or_create_config(chat_id),
         {:ok, value,  new_config} <- ChatConfig.update(config, k_v) do
      :ets.insert(__MODULE__, {chat_id, new_config})
      {:reply, value, state}
    else
      _ -> {:reply, :ignore, state}
    end
  end

  @impl true
  def handle_call(_msg, _from, state) do
  	{:reply, :ignore, state}
  end


  defp get_or_create_config(chat_id) do
    :ets.lookup(__MODULE__, chat_id)
    |> Enum.at(0)
    |> case do
         nil ->
           cfg = ChatConfig.new()
           :ets.insert(__MODULE__, {chat_id, cfg})
           cfg
         {_, config} -> config
       end
  end


  defmodule ChatConfig do
  	defstruct halt: false, riddle_duration: 60 * 1000
    @type t :: %ChatConfig{halt: boolean(), riddle_duration: pos_integer()}

    defguardp is_positive_integer(n) when is_integer(n) and n > 0

    @spec new(map()) :: ChatConfig.t()
    def new(map) when is_map(map), do: struct(ChatConfig, map)
    @spec new() :: ChatConfig.t()
    def new(), do: %ChatConfig{}


    @spec update(
      nil | SphinxBot.ConfigManager.ChatConfig.t() | any(),
      {bitstring()} | {bitstring(), any()}
    ) :: {:ok, any(), SphinxBot.ConfigManager.ChatConfig.t()} | :ignore
    def update(%ChatConfig{halt: halt}=config, ["halt"]) do
      Logger.debug("halt:: #{halt}")
      {:ok, !halt, %{config | halt: !halt}}
    end

    def update(%ChatConfig{}=config,["riddle_duration", value])
    when is_positive_integer(value) do
      {:ok, value, %{config | riddle_duration: value}}
    end

    def update(nil, k_v) do
      update(%ChatConfig{}, k_v)
    end

    def update(_, _) do
      :ignore
    end

    def as_map(%ChatConfig{}=config) do
      Map.from_struct(config)
    end
  end
end
