import Config

# Configure the database
config :boxfan, Data.Repo,
  database: "boxfan_dev.db",
  pool_size: 1,
  show_sensitive_data_on_connection_error: true

# Configure Phoenix endpoint for development
config :boxfan, Web.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "boxfan_dev_secret_key_base_needs_to_be_at_least_64_bytes_long_so_here",
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Enable LiveView debugging for Tidewave
config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: true
