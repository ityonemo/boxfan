# Boxfan - Nerves-based Fan Controller

## CRITICAL: MCP Integration

### Tidewave MCP (Elixir Development)

**This project uses Tidewave MCP server for enhanced Elixir development capabilities.**

Tidewave provides the following MCP tools available at `http://localhost:4000/tidewave/mcp`:

1. **`get_logs`** - Returns log output (excluding tool-caused logs)
   - Required params: `tail` (integer) - number of log entries to return
   - Optional params: `grep` (string) - filter logs with regex (case insensitive)
   - Use to check request logs or logged errors

2. **`get_source_location`** - Returns source location for modules/functions
   - Required params: `reference` (string) - Module, Module.function, or Module.function/arity
   - Also supports: `dep:PACKAGE_NAME` to get dependency location
   - Works for project modules and dependencies (not Elixir stdlib)

3. **`get_docs`** - Returns documentation for modules/functions
   - Required params: `reference` (string) - Module, Module.function, or Module.function/arity
   - Prefix with `c:` for callback documentation
   - Works for project and dependencies

4. **`project_eval`** - Evaluates Elixir code in project context (Elixir 1.18.4)
   - Required params: `code` (string) - Elixir code to evaluate
   - Optional params: `timeout` (integer, default 30000ms), `arguments` (array)
   - Includes IEx helpers (e.g., `exports(Module)`)
   - Returns stdout output
   - **ALWAYS use this instead of shell tools for Elixir code evaluation**

5. **`execute_sql_query`** - Executes SQL against Ecto repository
   - Required params: `query` (string) - SQL query with parameter placeholders
   - Optional params: `arguments` (array), `repo` (string, default: Data.Repo)
   - Limited to 50 rows per query (use LIMIT/OFFSET for more)
   - Available repo: Data.Repo (Ecto.Adapters.SQLite3)
   - Data in low-level format (UUIDs as 16-byte binaries, etc.)

6. **`get_ecto_schemas`** - Lists all Ecto schema modules and file paths
   - No parameters required
   - Use to find specific schemas instead of grepping filesystem

7. **`search_package_docs`** - Searches Hex documentation
   - Required params: `q` (string) - search query
   - Optional params: `packages` (array of strings) - filter by package names
   - Searches project dependencies by default

### Chrome DevTools MCP (Browser Testing)

**This project uses Chrome DevTools MCP server for automated browser testing of the Phoenix LiveView dashboard.**

Chrome DevTools provides browser automation capabilities with the `mcp__chrome-devtools__` prefix:

#### Page Management
- **`list_pages`** - List all open browser pages
  - Returns array of pages with index and URL
  - Shows which page is currently selected

- **`select_page`** - Switch to a different page/tab
  - Required params: `pageIdx` (number) - page index from list_pages

- **`navigate_page`** - Navigate current page to URL
  - Required params: `url` (string) - URL to navigate to
  - Optional params: `timeout` (integer, milliseconds)

- **`new_page`** - Open new page/tab
  - Required params: `url` (string) - URL to load
  - Optional params: `timeout` (integer, milliseconds)

- **`close_page`** - Close a page by index
  - Required params: `pageIdx` (number)
  - Cannot close the last open page

#### Page Inspection
- **`take_snapshot`** - Get text-based snapshot of page (a11y tree)
  - Optional params: `verbose` (boolean) - include all a11y tree info
  - Returns elements with unique identifiers (uid)
  - **Prefer this over screenshots** - faster and more accurate

- **`take_screenshot`** - Capture visual screenshot
  - Optional params: `uid` (string) - element to screenshot, `fullPage` (boolean), `format` (string: "png"/"jpeg"/"webp"), `quality` (number: 0-100), `filePath` (string)
  - Returns base64 image or saves to file

#### Interaction
- **`click`** - Click an element
  - Required params: `uid` (string) - element uid from snapshot
  - Optional params: `dblClick` (boolean) - double click

- **`fill`** - Type into input/textarea or select from dropdown
  - Required params: `uid` (string) - element uid, `value` (string) - text to enter

- **`fill_form`** - Fill multiple form fields at once
  - Required params: `elements` (array) - array of {uid, value} objects

- **`hover`** - Hover over element
  - Required params: `uid` (string) - element uid

- **`upload_file`** - Upload file through input element
  - Required params: `uid` (string) - element uid, `filePath` (string) - local file path

#### JavaScript Execution
- **`execute_script`** - Run JavaScript in page context
  - Required params: `function` (string) - JavaScript function declaration
  - Optional params: `args` (array) - arguments with {uid} objects
  - Returns JSON-serializable results
  - Example: `"() => { return document.title }"` or `"(el) => { return el.innerText }"`

#### Debugging & Monitoring
- **`list_console_messages`** - Get console logs
  - Optional params: `types` (array) - filter by types (log/error/warn/etc.), `pageSize` (integer), `pageIdx` (integer), `includePreservedMessages` (boolean)

- **`get_console_message`** - Get detailed console message
  - Required params: `msgid` (number) - message ID from list

- **`list_network_requests`** - Get network requests
  - Optional params: `resourceTypes` (array) - filter by types (xhr/fetch/document/etc.), `pageSize` (integer), `pageIdx` (integer), `includePreservedRequests` (boolean)

- **`get_network_request`** - Get detailed network request info
  - Required params: `reqid` (number) - request ID from list

#### Waiting & Dialogs
- **`wait_for`** - Wait for text to appear on page
  - Required params: `text` (string) - text to wait for
  - Optional params: `timeout` (integer, milliseconds)

- **`handle_dialog`** - Handle browser dialogs (alert/confirm/prompt)
  - Required params: `action` (string) - "accept" or "dismiss"
  - Optional params: `promptText` (string) - text to enter in prompt

#### Performance Testing
- **`performance_start_trace`** - Start performance recording
  - Required params: `reload` (boolean) - reload page after starting, `autoStop` (boolean) - stop automatically

- **`performance_stop_trace`** - Stop performance recording and get results
  - Returns Core Web Vitals and performance insights

- **`performance_analyze_insight`** - Get details on specific performance insight
  - Required params: `insightName` (string) - insight name from trace results

#### Advanced
- **`resize_page`** - Change page/viewport dimensions
  - Required params: `width` (number), `height` (number)

- **`emulate_network`** - Throttle network connection
  - Required params: `throttlingOption` (string) - "No emulation", "Offline", "Slow 3G", "Fast 3G", "Slow 4G", "Fast 4G"

- **`emulate_cpu`** - Throttle CPU performance
  - Required params: `throttlingRate` (number) - 1-20x slowdown factor

### Testing Dashboard Example

To test the Boxfan LiveView dashboard buttons:

```
1. List pages to see current state:
   mcp__chrome-devtools__list_pages

2. Navigate to dashboard:
   mcp__chrome-devtools__navigate_page
   - url: "http://localhost:4000/"

3. Take snapshot to get button UIDs:
   mcp__chrome-devtools__take_snapshot
   - This shows all interactive elements with unique identifiers

4. Click a button using its UID:
   mcp__chrome-devtools__click
   - uid: "..." (from snapshot)

5. Verify state changed:
   mcp__chrome-devtools__take_snapshot
   - Check button classes and GPIO state

6. Check for JavaScript errors:
   mcp__chrome-devtools__list_console_messages
   - types: ["error"]
```

**Key Testing Pattern:**
- Always use `take_snapshot` first to get element UIDs
- Use UIDs from snapshot for `click`, `fill`, `hover` operations
- Snapshot is faster and more reliable than screenshots
- Check console messages and network requests for debugging

## CRITICAL: Development Skills

**This project has specialized skills that provide essential workflow guidance. ALWAYS use these skills before starting relevant work.**

### Available Skills

**When implementing ANY new feature:**
1. ✅ USE `tdd-workflow` skill FIRST - Understand the strict TDD process
   - Write tests before implementation
   - Microfeature commits
   - Red-Green-Refactor cycle

**When writing tests:**
2. ✅ USE `testing-strategy` skill - Understand test organization
   - Test file placement (colocated with source)
   - Hardware mocking patterns for GPIO/I2C
   - SQLite test configuration

**When working with database/schemas:**
3. ✅ USE `database-guidelines` skill
   - Schema conventions
   - Changeset patterns
   - Migration best practices
   - SQLite-specific considerations

**When working with GenServers:**
4. ✅ USE `genserver-router-pattern` skill
   - Code organization patterns
   - Router pattern for handle_* functions
   - API and implementation separation

**When handling errors:**
5. ✅ USE `error-handling` skill
   - Fail-fast vs defensive approaches
   - Configuration validation patterns

**Before making commits:**
6. ✅ USE `git-workflow` skill
   - Commit message conventions
   - Atomic commit guidelines

**When using Mix module:**
7. ✅ USE `mix-module-usage` skill
   - Compile-time vs runtime patterns
   - Conditional compilation for different targets

### Workflow Rules

**CRITICAL: When implementing features with code changes:**
1. Load `tdd-workflow` skill FIRST
2. Load `testing-strategy` skill if writing tests
3. Write tests BEFORE implementation
4. Only then write the implementation
5. Load `git-workflow` skill before committing
6. Commit following TDD microfeature approach

**Rule of thumb:** If you're about to write production code, load `tdd-workflow` first. If you're about to commit, load `git-workflow` first.

## Project Overview

A Nerves-based embedded system for controlling a box fan via relay board, with VOC sensor monitoring and web interface. Deployed on Raspberry Pi with remote access via Tailscale.

## Hardware

- **Platform**: Raspberry Pi (any model)
- **Relay Board**: Electronics-Salon RPi Power Relay Board (3 relays)
  - Model: RPi Power Relay Board Expansion Module
  - Compatible with: Raspberry Pi A+ B+ 2B 3B 3B+ 4B
  - Relay specs: 10A/250VAC, 5A/30VDC (Panasonic JS1-5V-F)
  - Relay 1 (CH1): Fan speed level 1 - GPIO 26 (BCM), Pin 37
  - Relay 2 (CH2): Fan speed level 2 - GPIO 20 (BCM), Pin 38
  - Relay 3 (CH3): Fan speed level 3 - GPIO 21 (BCM), Pin 40
  - **Control Logic**: Active HIGH (relay activates when GPIO outputs HIGH)
  - **Constraint**: Only one relay should be active at a time
  - **Important**: Relay_JMP jumper must be connected for Pi control
- **Sensor**: Adafruit BME680 - Temperature, Humidity, Pressure & Gas Sensor
  - Interface: I2C (default address 0x77, alternate 0x76 with SDO→GND jumper)
  - Measurements:
    - Temperature: ±1.0°C accuracy
    - Humidity: ±3% accuracy
    - Barometric Pressure: ±1 hPa absolute accuracy
    - Gas/VOC: Resistance value in ohms (lower = higher VOC concentration)
  - **Note**: Gas resistance takes ~30 minutes to stabilize after power-on
  - Sampling: Every 60 seconds
  - Data Retention: 1 month (43,200 readings), older data automatically purged
- **Network**: Tailscale VPN for remote access

## Core Features

### 1. Relay Control
- Three relays corresponding to fan speeds 1, 2, 3
- Mutual exclusion: Never allow more than one relay to be on simultaneously
- GPIO-based control via Elixir Circuits

### 2. Event Logging
- SQLite database storing all relay events
- Each event records:
  - Timestamp
  - Relay number (1, 2, or 3)
  - Action (on/off)
  - Source (manual/automatic)

### 3. Sensor Data Logging
- SQLite database storing BME680 sensor readings
- Sample every 60 seconds
- Each reading records:
  - Timestamp
  - Temperature (°C)
  - Humidity (%)
  - Pressure (hPa)
  - Gas resistance (Ω)
- **Data Retention**: Keep 1 month of data (43,200 readings)
- Automatic purging of readings older than 30 days

### 4. Web Interface (Phoenix)
- **Dashboard**:
  - Display relay events from SQLite database
  - Manual control buttons for each fan speed (1, 2, 3, off)
  - Current fan status display
  - **Sensor Data Display**:
    - Current readings: Temperature, Humidity, Pressure, Gas resistance
    - Historical data charts (selectable time range):
      - Hour view: Last 60 readings (1 per minute)
      - **Day view (default)**: Last 24 hours (1,440 readings)
      - Week view: Last 7 days (10,080 readings)
      - Month view: Last 30 days (43,200 readings)
    - Charts for each metric: Temperature, Humidity, Pressure, Gas
- Simple, functional UI for embedded device

### 5. Automated Scheduling
- **Periodic ventilation**: Every 60 minutes, turn on fan at level 1 for 5 minutes
- Implemented via simple GenServer with Process.send_after
- All automated actions logged to database

### 6. BME680 Sensor Integration
- I2C communication for sensor readings
- Periodic sampling every 60 seconds
- Measures: Temperature, Humidity, Pressure, Gas resistance
- All readings stored in SQLite with automatic data retention management
- Real-time display on web dashboard
- Historical charts with multiple time range views

### 7. Remote Access
- Tailscale integration for secure remote access
- Access web interface over Tailscale network without port forwarding

## Technical Stack

### Nerves/Elixir Components
- **Nerves**: Embedded Linux platform
- **Phoenix**: Web framework (LiveView optional for real-time updates)
- **Ecto + SQLite**: Database layer (Ecto SQLite3 adapter)
- **Circuits GPIO**: Relay control
- **Circuits I2C**: VOC sensor communication
- **Tailscale**: VPN connectivity (via nerves_pack or custom integration)

### Database Schema

```sql
-- events table (relay control events)
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  relay_number INTEGER NOT NULL,  -- 1, 2, or 3
  action TEXT NOT NULL,            -- 'on' or 'off'
  source TEXT NOT NULL,            -- 'manual' or 'automatic'
  inserted_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
CREATE INDEX events_inserted_at_idx ON events(inserted_at);

-- sensor_readings table (BME680 data)
CREATE TABLE sensor_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  temperature REAL NOT NULL,       -- Celsius
  humidity REAL NOT NULL,          -- Percentage
  pressure REAL NOT NULL,          -- hPa (hectopascals)
  gas_resistance REAL NOT NULL,    -- Ohms
  inserted_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
CREATE INDEX sensor_readings_inserted_at_idx ON sensor_readings(inserted_at);
```

## Architecture

```
┌─────────────────────────────────────────┐
│         Phoenix Web Interface           │
│  (Event List + Manual Control Buttons)  │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│        Boxfan.FanController             │
│  (Relay Logic + Mutual Exclusion)       │
└──────┬───────────┬──────────────────────┘
       │           │
       ▼           ▼
┌─────────────┐   ┌──────────────────────┐
│ GPIO Driver │   │  Ecto + SQLite       │
│ (Relays)    │   │  (Event Logging)     │
└─────────────┘   └──────────────────────┘

┌─────────────────────────────────────────┐
│   Boxfan.Scheduler GenServer            │
│  → Every 60 min: set_relay(1)           │
│  → After 5 min: set_relay(0)            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      Boxfan.AirSensor GenServer         │
│  → Sample every 60s: Temp, Humidity,    │
│     Pressure, Gas resistance            │
│  → Store in SQLite sensor_readings      │
│  → Purge data older than 30 days        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          Tailscale (nerves_pack)        │
│     (VPN access to web interface)       │
└─────────────────────────────────────────┘
```

## Configuration

### GPIO Pin Mapping
```elixir
# Electronics-Salon RPi Power Relay Board
# Active HIGH logic - relays activate when GPIO outputs HIGH (1)
config :boxfan, Boxfan.FanController,
  relay_pins: %{
    1 => 26,  # Fan speed 1 (CH1, Pin 37)
    2 => 20,  # Fan speed 2 (CH2, Pin 38)
    3 => 21   # Fan speed 3 (CH3, Pin 40)
  }
```

### I2C Configuration
```elixir
config :boxfan, Boxfan.AirSensor,
  bus: "i2c-1",
  address: 0x77,  # Adafruit BME680 default address (0x76 if SDO→GND jumper)
  sample_interval: :timer.seconds(60),  # Sample every 60 seconds
  data_retention_days: 30  # Keep 30 days of data
```

### Scheduler Configuration
```elixir
config :boxfan, Boxfan.Scheduler,
  ventilation_interval: :timer.minutes(60),  # Run every 60 minutes
  ventilation_duration: :timer.minutes(5)    # Run for 5 minutes
```

## Development Workflow

```bash
# Install dependencies
mix deps.get

# Run on host for development
mix phx.server

# Build firmware for RPi (example: RPi 4)
export MIX_TARGET=rpi4
mix deps.get
mix firmware

# Burn to SD card
mix burn

# Upload firmware to running device
mix upload boxfan.local
```

## Safety Considerations

1. **Relay Mutual Exclusion**: Always ensure only one relay is active
2. **Active HIGH Logic**: Relays activate on HIGH (1), deactivate on LOW (0)
3. **GPIO Cleanup**: Properly release GPIO pins on shutdown (set all LOW to deactivate)
4. **Hardware Setup**: Verify Relay_JMP jumper is connected for Pi control
5. **Database Locking**: Handle SQLite concurrent access properly
6. **Error Recovery**: Ensure relay state is safe on crash/restart (default all relays OFF)

## Key Dependencies

```elixir
# Phoenix and web
{:phoenix, "~> 1.7"},
{:phoenix_html, "~> 4.0"},
{:phoenix_live_view, "~> 0.20"},
{:plug_cowboy, "~> 2.7"},
{:jason, "~> 1.4"},
{:heroicons, "~> 0.5"},
{:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
{:tailwind, "~> 0.3.1", runtime: Mix.env() == :dev},

# Database
{:ecto_sql, "~> 3.11"},
{:ecto_sqlite3, "~> 0.15"},

# Hardware interfacing
{:circuits_gpio, "~> 2.0"},
{:circuits_i2c, "~> 2.0"},
{:elixir_bme680, "~> 0.2.2"},

# Test dependencies
{:mox, "~> 1.0", only: :test},
{:mishras, "~> 0.1", only: :test},
{:faker, "~> 0.18", only: :test},

# Dev dependencies
{:tidewave, "~> 0.1", only: :dev},

# Nerves
{:nerves, "~> 1.10", runtime: false},
{:nerves_pack, "~> 0.7.1", targets: @all_targets},
```

## Architectural Guidelines

This project follows domain-driven design principles adapted from the techo project architecture.

### Directory Structure

```
lib/
├── boxfan/                        # Application context (business logic)
│   ├── application.ex             # OTP application supervisor tree
│   ├── fan_controller.ex          # Fan control GenServer (relay logic)
│   ├── air_sensor.ex              # BME680 sensor GenServer (sampling)
│   ├── scheduler.ex               # Scheduling GenServer (periodic ventilation)
│   ├── tailscale.ex               # Tailscale VPN connection management
│   ├── release.ex                 # Database migration runner for releases
│   ├── gpio_behaviour.ex          # GPIO interface specification
│   └── bme680_behaviour.ex        # BME680 interface specification
├── data/                          # Data layer (schemas and repo)
│   ├── repo.ex                    # Ecto repository (SQLite)
│   ├── event.ex                   # Event schema
│   └── sensor_reading.ex          # SensorReading schema
├── web/                           # Web layer (Phoenix components)
│   ├── endpoint.ex                # Phoenix endpoint configuration
│   ├── router.ex                  # Application routing
│   ├── layouts.ex                 # Layout components
│   ├── error_html.ex              # Error page templates
│   ├── dashboard_live.ex          # Main dashboard LiveView
│   └── components/
│       └── sensor_chart.ex        # SVG chart LiveComponent
└── boxfan.ex                      # Main module

host/                              # Host mode implementations (development)
├── gpio.ex                        # Mock GPIO using application env
└── bme680.ex                      # Simulated sensor readings

support/                           # Test support code (compiled only in :test)
├── mocks.ex                       # Mox mock definitions
├── data_case.ex                   # DataCase for database tests
└── mishras/                       # Factory implementations
    ├── event.ex                   # Event factory
    └── sensor_reading.ex          # SensorReading factory
```

### Key Architectural Principles

#### 1. Domain-Driven Design
- **Contexts** group related functionality (`Boxfan.FanController`, `Boxfan.AirSensor`, `Boxfan.Scheduler`)
- **Schemas** define data structures (`Data.Event`, `Data.SensorReading`)
- **Business logic** stays in context modules (GenServers), not LiveViews
- **LiveViews** handle only presentation and user interaction

#### 2. Colocated Testing
- Tests live next to the code they test
- Example: `live.ex` and `live_test.exs` in same directory
- Easier to maintain and discover tests

#### 3. GenServer-Based Controllers
- `Boxfan.FanController` manages relay state and mutual exclusion
- `Boxfan.AirSensor` polls BME680 sensor every 60s, stores readings, purges old data
- `Boxfan.Scheduler` handles periodic ventilation using Process.send_after
- `Boxfan.Tailscale` manages VPN connection via MuonTrap daemon
- State management centralized in GenServers
- LiveView subscribes to GenServer updates via PubSub

#### 4. Supporting Modules
- `Boxfan.Release` - Runs Ecto migrations on boot for Nerves devices
- `Web.Components.SensorChart` - SVG LiveComponent for historical data visualization
  - Supports multiple metrics (temperature, humidity, pressure, gas resistance)
  - Time range selection (hour, day, week, month)
  - Fan cycle visualization as amber gradients
  - Responsive SVG with proper axis scaling

#### 5. Data Layer Separation
- All database interactions through `Data.Repo`
- Schemas in `data/` directory
- Contexts use Ecto changesets for validation

### Data Flow

```
User Action → LiveView → FanController GenServer → GPIO + Event Logging
                              ↓
                         PubSub Broadcast
                              ↓
                      LiveView Updates UI

Scheduler → FanController → GPIO + Event Logging
```

### Schemas

All schemas follow conventions defined in the `database-guidelines` skill. See `lib/data/event.ex` and `lib/data/sensor_reading.ex` for implementations.

### GenServer Pattern

All GenServers follow the Router Pattern defined in the `genserver-router-pattern` skill. See `lib/boxfan/fan_controller.ex` for a reference implementation.

### LiveView Patterns

- Use LiveView for real-time UI updates
- Subscribe to PubSub for GenServer state changes
- Keep LiveView thin - delegate to GenServers
- Use `handle_event/3` for user actions
- Use `handle_info/2` for PubSub messages

### Testing Strategy

#### Test Organization
- **Colocated tests**: Tests live next to code they test (e.g., `lib/data/event_test.exs`)
- **Support files**: Test support code in `support/` directory (only compiled in `:test` env)
- **DataCase**: Base test case for database tests with sandbox setup
- **ConnCase**: Base test case for LiveView/controller tests

#### Test Categories
1. **Unit Tests**: GenServer logic, changesets
2. **Integration Tests**: LiveView interactions with `Phoenix.LiveViewTest`
3. **Hardware Mocks**: Mock GPIO and I2C for testing without hardware

#### Test Configuration
- SQLite for test database (fast, isolated)
- Mock GPIO/I2C modules for testing
- Sandbox mode for database isolation
- Async tests where possible (async: false for SQLite writes)

#### Factories (using Mishras library)
- Factory implementations in `support/mishras/`
- Protocol-based pattern: `defimpl Mishras.Factory, for: Data.Event`
- Two modes: `:build` (no DB) and `:insert` (with DB)
- Usage: `Factory.insert(Data.Event, %{relay_number: 1})`
- Faker library for generating test data

### Hardware Mocking Strategy

Hardware-dependent code uses a behavior-based abstraction with three implementation tiers:

1. **Behaviors** define the interface (`lib/boxfan/gpio_behaviour.ex`, `lib/boxfan/bme680_behaviour.ex`)
2. **Host implementations** provide dev-mode simulation (`host/gpio.ex`, `host/bme680.ex`)
3. **Mox mocks** enable precise test assertions (`support/mocks.ex`)

#### Behaviors

```elixir
# lib/boxfan/gpio_behaviour.ex
defmodule Boxfan.GPIOBehaviour do
  @callback open(pin :: non_neg_integer(), direction :: :input | :output) ::
              {:ok, reference()} | {:error, term()}
  @callback write(ref :: reference(), value :: 0 | 1) :: :ok | {:error, term()}
  @callback close(ref :: reference()) :: :ok
end

# lib/boxfan/bme680_behaviour.ex
defmodule Boxfan.Bme680Behaviour do
  @callback measure(name :: atom()) :: Bme680.Measurement.t()
end
```

#### Configuration-Based Module Selection

```elixir
# config/test.exs - Mox mocks for precise assertions
config :boxfan, :gpio, Boxfan.GPIOMock
config :boxfan, :bme680, Boxfan.Bme680Mock

# config/host.exs - Simulated hardware for development
config :boxfan, :gpio, Host.GPIO
config :boxfan, :bme680, Host.Bme680

# config/target.exs - Real hardware on Nerves device
config :boxfan, :gpio, Circuits.GPIO
config :boxfan, :bme680, Bme680
```

#### Mox Mock Definitions

```elixir
# support/mocks.ex
Mox.defmock(Boxfan.GPIOMock, for: Boxfan.GPIOBehaviour)
Mox.defmock(Boxfan.Bme680Mock, for: Boxfan.Bme680Behaviour)
```

#### Usage in GenServers

```elixir
defmodule Boxfan.FanController do
  @gpio Application.compile_env!(:boxfan, :gpio)

  def init(opts) do
    relay_pins = Keyword.fetch!(opts, :relay_pins)

    refs = Enum.map(relay_pins, fn {relay, pin} ->
      {:ok, ref} = @gpio.open(pin, :output)
      @gpio.write(ref, 0)  # LOW = OFF (Active HIGH)
      {relay, {pin, ref}}
    end)

    {:ok, %{pins: Map.new(refs), current_relay: nil}}
  end
end
```

#### Test Example with Mox

```elixir
defmodule Boxfan.FanControllerTest do
  use ExUnit.Case, async: false
  import Mox

  setup :verify_on_exit!

  test "sets relay 1 on by writing HIGH" do
    ref = make_ref()

    Boxfan.GPIOMock
    |> expect(:open, 3, fn _pin, :output -> {:ok, ref} end)
    |> expect(:write, 3, fn ^ref, 0 -> :ok end)  # Initial OFF state
    |> expect(:write, fn ^ref, 1 -> :ok end)     # Turn ON relay 1

    {:ok, _pid} = Boxfan.FanController.start_link(relay_pins: %{1 => 26, 2 => 20, 3 => 21})
    Boxfan.FanController.set_relay(1)
  end
end
```

### Web Module Structure (Explicit, No Complex Macros)

Following the techo project pattern, we keep the Web module simple and explicit:

```elixir
# lib/web.ex
defmodule Web do
  @moduledoc """
  The Web context for Phoenix components.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  defmodule VerifiedRoutes do
    @moduledoc """
    Verified routes for compile-time route verification.
    """
    defmacro __using__(_opts) do
      quote do
        use Phoenix.VerifiedRoutes,
          endpoint: Web.Endpoint,
          router: Web.Router,
          statics: Web.static_paths()
      end
    end
  end
end
```

**Key Points:**
- Simple module, no complicated Phoenix macros
- Explicit static paths configuration
- VerifiedRoutes provides single macro for tests and LiveViews
- Used via `use Web.VerifiedRoutes` in tests

### Configuration Management

```elixir
# config/target.exs
config :boxfan, Boxfan.FanController,
  relay_pins: %{
    1 => 26,  # GPIO pin for relay 1 (CH1, Pin 37) - Active HIGH
    2 => 20,  # GPIO pin for relay 2 (CH2, Pin 38) - Active HIGH
    3 => 21   # GPIO pin for relay 3 (CH3, Pin 40) - Active HIGH
  }

config :boxfan, Boxfan.AirSensor,
  bus: "i2c-1",
  address: 0x77,
  sample_interval: :timer.seconds(60),
  data_retention_days: 30

config :boxfan, Boxfan.Scheduler,
  ventilation_interval: :timer.minutes(60),
  ventilation_duration: :timer.minutes(5)
```

## Notes

- This is a simple, straightforward implementation
- Focus on reliability and safety (relay mutual exclusion)
- Keep web interface minimal and functional
- Ensure all state changes are logged for debugging and monitoring
- **Avoid overarchitecting**: Build only what's needed now
- **YAGNI principle**: Don't add features/config for future use cases
