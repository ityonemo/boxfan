# Boxfan Deployment Guide

## Prerequisites

1. **Raspberry Pi** (any model, but RPi 4 recommended)
2. **MicroSD card** (16GB+ recommended)
3. **SSH key** at `~/.ssh/id_*.pub` (required for device access)
4. **Tailscale account** and auth key from https://login.tailscale.com/admin/settings/keys

## Required Environment Variables

### 1. SECRET_KEY_BASE (Required)
Generate a secure random key for Phoenix:

```bash
export SECRET_KEY_BASE=$(mix phx.gen.secret)
```

### 2. TAILSCALE_AUTH_KEY (Required)
Get from https://login.tailscale.com/admin/settings/keys

- Click "Generate auth key"
- Enable "Reusable" (recommended for easier re-deployments)
- Enable "Ephemeral" (optional - device disappears from network when offline)
- Copy the key

```bash
export TAILSCALE_AUTH_KEY="tskey-auth-XXXXXXXXXXXXXXXX"
```

### 3. MIX_TARGET (Required)
Set your Raspberry Pi model:

```bash
# For Raspberry Pi 4:
export MIX_TARGET=rpi4

# For Raspberry Pi 3:
export MIX_TARGET=rpi3

# For Raspberry Pi Zero 2 W:
export MIX_TARGET=rpi0_2

# See mix.exs lines 6-20 for all supported targets
```

### 4. WiFi Configuration (Optional)
If you want to use WiFi instead of ethernet, set these before building:

```bash
export WIFI_SSID="your_network_name"
export WIFI_PSK="your_wifi_password"
export WIFI_REGULATORY_DOMAIN="US"  # Your 2-letter country code
```

**Note**: If WiFi variables are not set, the device will default to ethernet. You can configure WiFi later via SSH if needed (see WiFi Configuration section below).

## Complete Deployment Commands

### First Time Deployment (New SD Card)

```bash
# 1. Set environment variables
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export TAILSCALE_AUTH_KEY="tskey-auth-XXXXXXXXXXXXXXXX"
export MIX_TARGET=rpi4

# Optional: Configure WiFi (skip if using ethernet)
export WIFI_SSID="your_network_name"
export WIFI_PSK="your_wifi_password"
export WIFI_REGULATORY_DOMAIN="US"

# 2. Get dependencies
mix deps.get

# 3. Build firmware
mix firmware

# 4. Burn to SD card (will prompt for device, e.g., /dev/sdb)
mix burn

# 5. Insert SD card into Raspberry Pi and power on
# Device will boot and automatically join Tailscale network
```

### Updating Existing Device

```bash
# 1. Set environment variables (if not already set)
export SECRET_KEY_BASE="your_existing_secret_key"
export TAILSCALE_AUTH_KEY="tskey-auth-XXXXXXXXXXXXXXXX"
export MIX_TARGET=rpi4

# 2. Build firmware
mix firmware

# 3. Upload over network (device must be reachable)
mix upload boxfan.local
# or
mix upload nerves-XXXX.local
# or over Tailscale IP
mix upload 100.x.x.x
```

## Post-Deployment Access

### Local Network Access

- **mDNS**: `http://nerves-XXXX.local` or `http://boxfan.local`
- **Direct IP**: Check your router for device IP

### Tailscale Access (from anywhere!)

1. Find your device in Tailscale admin: https://login.tailscale.com/admin/machines
2. Look for the assigned IP (e.g., `100.64.0.5`)
3. Access dashboard: `http://100.64.0.5`

### SSH Access

```bash
# Local network
ssh nerves-XXXX.local

# Tailscale
ssh 100.x.x.x
```

## Hardware Setup

### GPIO Connections (Electronics-Salon RPi Power Relay Board)

**CRITICAL**: Ensure the `Relay_JMP` jumper is connected on the relay board!

- **Relay 1** (Fan Speed 1): GPIO 26 (BCM) / Pin 37
- **Relay 2** (Fan Speed 2): GPIO 20 (BCM) / Pin 38
- **Relay 3** (Fan Speed 3): GPIO 21 (BCM) / Pin 40
- **Control Logic**: Active LOW (relay activates when GPIO outputs LOW)

### BME680 Sensor Connections (I2C)

- **SDA**: GPIO 2 (BCM) / Pin 3
- **SCL**: GPIO 3 (BCM) / Pin 5
- **VCC**: 3.3V (Pin 1 or 17)
- **GND**: Ground (Pin 6, 9, 14, 20, 25, 30, 34, or 39)
- **I2C Address**: 0x77 (default, or 0x76 if SDO→GND jumper is set)

## WiFi Configuration (Optional)

If you want to use WiFi instead of ethernet:

```bash
# Connect to device via ethernet first
ssh nerves-XXXX.local

# Configure WiFi
iex> VintageNet.configure("wlan0", %{
  type: VintageNetWiFi,
  vintage_net_wifi: %{
    networks: [
      %{
        key_mgmt: :wpa_psk,
        ssid: "your_network_name",
        psk: "your_password"
      }
    ]
  },
  ipv4: %{method: :dhcp}
})
```

## Troubleshooting

### Device Not Appearing on Network

1. Check ethernet cable connection
2. Verify power supply (Raspberry Pi needs 5V 3A for RPi 4)
3. Check SD card is properly inserted
4. Look for activity LED on Raspberry Pi

### Cannot Access Web Interface

1. Verify device is on network: `ping boxfan.local`
2. Check Phoenix is running: `ssh boxfan.local` then check logs with `RingLogger.next()`
3. Verify port 80 is accessible (not blocked by firewall)

### Tailscale Not Working

1. Check auth key is valid and not expired
2. Verify nerves_pack is starting: check logs via SSH
3. Regenerate auth key if needed

### Fan Not Responding

1. Verify relay board power and jumper connection
2. Check GPIO connections to correct pins
3. SSH into device and check events table: `Data.Repo.all(Data.Event)`
4. Check host debug info in web interface

### Sensor Readings Not Showing

1. Verify I2C connections (SDA/SCL)
2. Check I2C address: `ssh boxfan.local` then `Circuits.I2C.detect_devices()`
3. Verify BME680 power (3.3V)
4. Check sensor readings in database: `Data.Repo.all(Data.SensorReading)`

## Environment Variable Management

Create a `.env` file (don't commit to git!):

```bash
# Copy the example file
cp .env.example .env

# Edit with your values
nano .env  # or vim, code, etc.
```

Example `.env` contents:

```bash
# .env
export SECRET_KEY_BASE="your_generated_secret_key_here"
export TAILSCALE_AUTH_KEY="tskey-auth-XXXXXXXXXXXXXXXX"
export MIX_TARGET=rpi4

# Optional WiFi (comment out if using ethernet)
export WIFI_SSID="your_network_name"
export WIFI_PSK="your_wifi_password"
export WIFI_REGULATORY_DOMAIN="US"
```

Then source it before deployment:

```bash
source .env
mix firmware
mix burn
```

## Schedule Configuration

Default settings (configured in `config/target.exs`):

- **Ventilation Interval**: Every 60 minutes
- **Ventilation Duration**: 5 minutes per cycle
- **Fan Speed**: Speed 1 (lowest)
- **Sensor Sampling**: Every 60 seconds
- **Data Retention**: 30 days

All cycles are logged to the database and visible in the web interface.

## Next Steps After Deployment

1. ✅ Access web dashboard via Tailscale
2. ✅ Verify sensor readings are appearing
3. ✅ Test manual fan control
4. ✅ Wait for first automatic ventilation cycle (1 second after boot)
5. ✅ Monitor fan cycle stripes on charts
6. ✅ Check event log for automatic cycles

Enjoy your smart box fan! 🌬️
