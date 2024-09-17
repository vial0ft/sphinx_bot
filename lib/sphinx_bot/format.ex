defmodule SphinxBot.Format do

  def add_sec_time_limit(text, limit) do
    "#{text}\nНа рзмышление #{limit} сек"
  end


  defp quote_username(username) do
    "\`#{username}\`"
  end

  @spec add_user(bitstring(), any()) :: bitstring()
  def add_user(
    text,
    %ExGram.Model.User{username: username, first_name: first_name, last_name: last_name}
  ) do
    name = if username, do: username, else: "#{first_name} #{last_name}"
    "Привет, #{quote_username(name)}\n#{text}"
  end
end
