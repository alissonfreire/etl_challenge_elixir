import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :etl_challenge, EtlChallenge.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :etl_challenge, EtlChallengeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "/MOhGIXDm/atUYxq49nKPsPBgwqyH7T/iL3VVoLbd2G/fzcOnoE2pcNMv1wL+hbN",
  server: false

# In test we don't send emails.
config :etl_challenge, EtlChallenge.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

config :etl_challenge, :page_api_url, System.get_env("PAGE_API_URL", "localhost:8000/api")

config :etl_challenge, :page_api_impl, EtlChallenge.Requests.Adapters.MockPageAPIImpl
