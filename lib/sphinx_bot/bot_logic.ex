defmodule SphinxBot.BotLogic do
  @moduledoc """
  Behaviour of bot
  """

  @type chat_user :: {ExGram.Model.Chat.t(), ExGram.Model.User.t()}
  @type send_func :: (chat_user, text :: bitstring(),  any() -> integer())

  @callback handle(:time) :: bitstring()
  @callback handle(:riddle, chat_user , send_func) :: any()
  @callback handle(:callback, chat_user, data ::any()) :: any()
  @callback handle(:new_chat_member, chat_user, send_func) ::any()
  @callback handle(:text, chat_user) ::any()
end
