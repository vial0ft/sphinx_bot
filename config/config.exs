import Config

config :ex_gram, token: System.get_env("TELEGRAM_APITOKEN")
config :sphinx, bot_id: System.get_env("BOT_ID")
