defmodule SphinxBot.Format do
  alias ExGram.Model

  def add_sec_time_limit(text, limit) do
    "#{text}\nНа размышление #{limit} сек"
  end

  defp quote_username(username) do
    "\`#{username}\`"
  end

  @spec add_user(bitstring(), Model.User.t()) :: bitstring()
  def add_user(
        text,
        %Model.User{username: username, first_name: first_name, last_name: last_name}
      ) do
    name = if username, do: username, else: "#{first_name} #{last_name}"
    "Привет, #{quote_username(name)}\n#{text}"
  end
end
