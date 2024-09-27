import Config

config :ex_gram, token: System.get_env("TELEGRAM_APITOKEN")
config :sphinx_bot, bot_id: System.get_env("BOT_ID")
