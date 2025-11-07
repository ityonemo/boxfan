import Config

# Add configuration that is only needed when running on the host here.

# Configure Host GPIO and BME680 implementations for development
config :boxfan, :gpio, Host.GPIO
config :boxfan, :bme680, Host.Bme680

# Configure hardware for host (same pins as target for consistency)
config :boxfan, Boxfan.FanController,
  relay_pins: %{
    # GPIO 26 (BCM), Pin 37 - Active HIGH
    1 => 26,
    # GPIO 20 (BCM), Pin 38 - Active HIGH
    2 => 20,
    # GPIO 21 (BCM), Pin 40 - Active HIGH
    3 => 21
  }

config :boxfan, Boxfan.AirSensor,
  bus: "i2c-1",
  address: 0x77,
  sample_interval: :timer.seconds(60),
  data_retention_days: 30

config :boxfan, Boxfan.Scheduler,
  ventilation_interval: :timer.minutes(60),
  ventilation_duration: :timer.minutes(5)

config :nerves_runtime,
  kv_backend:
    {Nerves.Runtime.KVBackend.InMemory,
     contents: %{
       # The KV store on Nerves systems is typically read from UBoot-env, but
       # this allows us to use a pre-populated InMemory store when running on
       # host for development and testing.
       #
       # https://hexdocs.pm/nerves_runtime/readme.html#using-nerves_runtime-in-tests
       # https://hexdocs.pm/nerves_runtime/readme.html#nerves-system-and-firmware-metadata

       "nerves_fw_active" => "a",
       "a.nerves_fw_architecture" => "generic",
       "a.nerves_fw_description" => "N/A",
       "a.nerves_fw_platform" => "host",
       "a.nerves_fw_version" => "0.0.0"
     }}

# Import environment-specific config
if config_env() == :test do
  import_config "test.exs"
else
  import_config "dev.exs"
end
