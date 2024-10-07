defmodule SphinxBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec init_riddle_data() :: map()
  def init_riddle_data do
    with {:ok, symbols_str} <- File.read("resources/clock_symbols.json"),
         {:ok, symbols} <- Jason.decode(symbols_str) do
      symbols
    else
      err -> raise err
    end
  end

  @impl true
  def start(_type, _args) do
    children = [
      ExGram,
      {SphinxBot.Bot,
       [
         method: {:polling, allowed_updates: ["message"]},
         token: Application.fetch_env!(:ex_gram, :token)
       ]},
      {Riddles.Clock.Riddle, init_riddle_data()},
      {Riddles.Store, :riddles},
      {SphinxBot.Background, []},
      {SphinxBot.ConfigManager, %{}},
      %{
        id: SphinxBot.RealBotLogic,
        start: {SphinxBot.RealBotLogic, :start_link, [%{timeout: 60 * 1000, pause: false}]}
      },
      {Infra.VisitLogger, %{log_dir: "log/"}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SphinxBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
