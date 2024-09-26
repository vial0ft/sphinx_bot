defmodule SphinxBot.RealBotLogicTest do
 alias Riddles.Store
	alias SphinxBot.RealBotLogic
  alias ExGram.Model
  use ExUnit.Case
  doctest SphinxBot.RealBotLogic

  test("time") do
    assert is_bitstring(RealBotLogic.time())
  end

  test("creating riddle and handle answer") do
    chat = %Model.Chat{id: 42}
    user = %Model.User{id: 43}
    responce_msg_id = 100
    ch_u = {chat, user}
    key = RealBotLogic.riddle_store_key(ch_u)
  	assert RealBotLogic.riddle(ch_u, mock_sender(responce_msg_id)) == {:ok, key}

    assert {:ok, {riddle, riddle_pid}} = Store.get(key)
    assert riddle != nil
    assert Process.alive?(riddle_pid)
  end

  defp mock_sender(resp_msg_id) do
    fn _ch_u, _text, _opts -> resp_msg_id end
  end
end
