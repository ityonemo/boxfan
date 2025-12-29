import Config

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Configure the database
config :boxfan, Data.Repo,
  database: "/root/boxfan.db",
  pool_size: 1

# Configure hardware adapters for target
config :boxfan, :gpio, Circuits.GPIO
config :boxfan, :bme680, Bme680

# Configure FanController GPIO pins
config :boxfan, Boxfan.FanController,
  relay_pins: %{
    # GPIO 26 (BCM), Pin 37 - Active HIGH
    1 => 26,
    # GPIO 20 (BCM), Pin 38 - Active HIGH
    2 => 20,
    # GPIO 21 (BCM), Pin 40 - Active HIGH
    3 => 21
  }

# Configure Air Sensor
config :boxfan, Boxfan.AirSensor,
  bus: "i2c-1",
  address: 0x77,
  sample_interval: :timer.seconds(60),
  data_retention_days: 30,
  ph_slope: 0.0847306932433938,
  gas_ceil: 2066586.8541392616

# Configure Scheduler
config :boxfan, Boxfan.Scheduler,
  ventilation_interval: :timer.minutes(60),
  ventilation_duration: :timer.minutes(5)

# Configure Phoenix endpoint for target
config :boxfan, Web.Endpoint,
  http: [port: 80, ip: {0, 0, 0, 0}],
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      Mix.raise(
        "SECRET_KEY_BASE environment variable is required. Generate with: mix phx.gen.secret"
      ),
  server: true,
  check_origin: false

# Use shoehorn to start the main application. See the shoehorn
# library documentation for more control in ordering how OTP
# applications are started and handling failures.

config :shoehorn, init: [:nerves_runtime, :nerves_pack]

# Note: Erlang distribution is started at runtime in Boxfan.Application
# Connect with: iex --name dev@<hostname>.local --cookie boxfan_cookie
# Then: Node.connect(:'boxfan@boxfan.local')

# Configure Tailscale for secure remote access
# Capture auth key at compile time to bake it into the firmware
config :boxfan,
       :tailscale_auth_key,
       System.get_env("TAILSCALE_AUTH_KEY") ||
         Mix.raise(
           "TAILSCALE_AUTH_KEY environment variable is required. Get from: https://login.tailscale.com/admin/settings/keys"
         )

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

# Advance the system clock on devices without real-time clocks.
config :nerves, :erlinit, update_clock: true

# Configure the device for SSH IEx prompt access and firmware updates
#
# * See https://hexdocs.pm/nerves_ssh/readme.html for general SSH configuration
# * See https://hexdocs.pm/ssh_subsystem_fwup/readme.html for firmware updates

keys =
  System.user_home!()
  |> Path.join(".ssh/id_{rsa,ecdsa,ed25519}.pub")
  |> Path.wildcard()

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :nerves_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

# Configure the network using vintage_net
#
# Update regulatory_domain to your 2-letter country code E.g., "US"
#
# See https://github.com/nerves-networking/vintage_net for more information

# Build WiFi configuration from environment variables
wifi_ssid = System.get_env("WIFI_SSID")
wifi_psk = System.get_env("WIFI_PSK")

wlan0_config =
  if wifi_ssid && wifi_psk do
    %{
      type: VintageNetWiFi,
      vintage_net_wifi: %{
        networks: [
          %{
            key_mgmt: :wpa_psk,
            ssid: wifi_ssid,
            psk: wifi_psk
          }
        ]
      },
      ipv4: %{method: :dhcp}
    }
  else
    # No WiFi credentials provided - interface will be unconfigured
    %{type: VintageNetWiFi}
  end

config :vintage_net,
  regulatory_domain: System.get_env("WIFI_REGULATORY_DOMAIN") || "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0", wlan0_config}
  ]

config :mdns_lite,
  # The `hosts` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  The `"boxfan"` host causes mdns_lite
  # to advertise "boxfan.local" for convenience. If more than one Nerves device
  # is on the network, it is recommended to delete "boxfan" from the list
  # because otherwise any of the devices may respond to boxfan.local leading to
  # unpredictable behavior.

  hosts: [:hostname, "boxfan"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
