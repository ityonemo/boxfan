import Config

# Mark environment as test so Application doesn't start hardware GenServers
config :boxfan, :env, :test

# Configure the database for tests
config :boxfan, Data.Repo,
  database: :memory,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1,
  migration_lock: nil

# Configure hardware mocks for testing
config :boxfan, :gpio, Boxfan.GPIOMock
config :boxfan, :bme680, Boxfan.Bme680Mock

# Configure hardware GenServers for testing
config :boxfan, Boxfan.FanController, relay_pins: %{1 => 26, 2 => 20, 3 => 21}

config :boxfan, Boxfan.AirSensor,
  bus: "i2c-1",
  address: 0x77,
  sample_interval: :timer.seconds(60),
  data_retention_days: 30

config :boxfan, Boxfan.Scheduler,
  ventilation_interval: :timer.minutes(60),
  ventilation_duration: :timer.minutes(5)

# We don't run a server during test
config :boxfan, Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "boxfan_test_secret_key_base_needs_to_be_at_least_64_bytes_long_here",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
