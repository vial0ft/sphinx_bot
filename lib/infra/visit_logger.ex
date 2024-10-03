defmodule Infra.VisitLogger do
  use GenServer

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(log_settings) do
    GenServer.start_link(__MODULE__, log_settings, name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, any()}
  def init(%{log_dir: dir} = state) do
    File.mkdir_p(dir)
    {:ok, state}
  end

  @spec log({:new_user | :ban | :left, {any(), any()}}) :: any()
  def log({event, {_chat, _user} = ch_u}) do
    GenServer.cast(__MODULE__, {event, ch_u})
  end

  @impl true
  def handle_cast({event, ch_u}, %{log_dir: dir} = state) do
    now = DateTime.utc_now()
    log_file = log_filename(dir, now)

    with {:ok, f} <- File.open(log_file, [:append]) do
      IO.binwrite(f, log_line(now, event, ch_u))
      File.close(f)
    end

    {:noreply, state}
  end

  defp log_filename(dir, %DateTime{day: day, month: month, year: year}) do
    Path.join(dir, "#{year}_#{month}_#{day}.log")
  end

  @spec log_line(%DateTime{}, atom(), {any(), any()}) :: bitstring()
  defp log_line(dt, event, ch_u) do
    "#{time_format(dt)} [#{event}] #{chat_user_format(ch_u)}\n"
  end

  def time_format(dt) do
    dt |> Calendar.strftime("%y-%m-%d %H:%M:%S")
  end

  defp chat_user_format({chat, user}) do
    info =
      Enum.join(
        [
          "\"chat_id\": \"#{chat.id}\"",
          "\"chat_title\": \"#{chat.title}\"",
          "\"user_id\": \"#{user.id}\"",
          "\"username\": \"#{user.username}\"",
          "\"full_name\": \"#{user.first_name} #{user.last_name}\""
        ],
        ", "
      )

    "{#{info}}"
  end
end
