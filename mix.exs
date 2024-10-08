defmodule SphinxBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :sphinx_bot,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx, :observer, :runtime_tools],
      mod: {SphinxBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_gram, "~> 0.53"},
      {:tesla, "~> 1.2"},
      {:jason, ">= 1.0.0"},
      {:hackney, "~> 1.12"}
    ]
  end
end
