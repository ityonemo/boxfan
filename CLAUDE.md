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
  - **Control Logic**: Active LOW (relay activates when GPIO outputs LOW)
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

-- Index for efficient time-range queries
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
│  → Every 60 min: set_speed(1)           │
│  → After 5 min: set_speed(0)            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│    Boxfan.BME680Sensor GenServer        │
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

## Implementation Plan

### Phase 1: Core Infrastructure
1. Add Phoenix dependencies to mix.exs
2. Set up Phoenix endpoint and router
3. Configure Ecto with SQLite adapter
4. Create events and sensor_readings table migrations
5. Set up basic Phoenix LiveView

### Phase 2: Relay Control
1. Configure GPIO pins for 3 relays
2. Implement `Boxfan.FanController` GenServer
   - State management for current relay
   - Mutual exclusion logic
   - Active LOW GPIO control
   - Event logging to SQLite
3. Create relay control API functions

### Phase 3: BME680 Sensor Integration
1. Configure I2C for BME680 (address 0x77)
2. Create `Boxfan.BME680Sensor` GenServer
   - Read temperature, humidity, pressure, gas resistance
   - Sample every 60 seconds using Process.send_after
   - Store readings in sensor_readings table
   - Implement data retention (purge records > 30 days old)
3. Create sensor data query functions

### Phase 4: Web Dashboard
1. Create dashboard LiveView
2. Display current sensor readings (real-time)
3. Display relay events from database
4. Add manual control buttons (Off, Speed 1, Speed 2, Speed 3)
5. Implement time-range selector (Hour/Day/Week/Month)
6. Create charts for historical sensor data:
   - Temperature chart
   - Humidity chart
   - Pressure chart
   - Gas resistance chart
7. Wire buttons to FanController
8. Subscribe to sensor updates via PubSub

### Phase 5: Scheduling
1. Implement `Boxfan.Scheduler` GenServer
2. Use Process.send_after for periodic ventilation:
   - Turn on fan at speed 1 every 60 minutes
   - Schedule turn-off after 5 minutes
3. Ensure events are logged with source='automatic'

### Phase 6: Tailscale Integration
1. Configure Tailscale via nerves_pack
2. Update rootfs_overlay for Tailscale auth
3. Test remote access over Tailscale network

## Configuration

### GPIO Pin Mapping
```elixir
# Electronics-Salon RPi Power Relay Board
# Active LOW logic - relays activate when GPIO outputs LOW (0)
config :boxfan, :relay_pins,
  relay1: 26,  # Fan speed 1 (CH1, Pin 37)
  relay2: 20,  # Fan speed 2 (CH2, Pin 38)
  relay3: 21   # Fan speed 3 (CH3, Pin 40)
```

### I2C Configuration
```elixir
config :boxfan, Boxfan.BME680Sensor,
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
2. **Active LOW Logic**: Remember relays activate on LOW (0), deactivate on HIGH (1)
3. **GPIO Cleanup**: Properly release GPIO pins on shutdown (set all HIGH to deactivate)
4. **Hardware Setup**: Verify Relay_JMP jumper is connected for Pi control
5. **Database Locking**: Handle SQLite concurrent access properly
6. **Error Recovery**: Ensure relay state is safe on crash/restart (default all relays OFF)

## Future Enhancements

- Gas resistance-based automatic fan control (e.g., increase speed when gas resistance drops below threshold, indicating high VOC)
- Scheduling customization via web interface
- Multiple scheduling profiles
- Push notifications for high VOC levels or temperature alerts
- Export sensor data to CSV
- Air Quality Index (AQI) calculation from BME680 readings

## Dependencies to Add

```elixir
# Phoenix and web
{:phoenix, "~> 1.7"},
{:phoenix_html, "~> 4.0"},
{:phoenix_live_view, "~> 0.20"},
{:plug_cowboy, "~> 2.7"},
{:jason, "~> 1.4"},
{:heroicons, "~> 0.5"},

# Database
{:ecto_sql, "~> 3.11"},
{:ecto_sqlite3, "~> 0.15"},

# Hardware interfacing
{:circuits_gpio, "~> 2.0"},
{:circuits_i2c, "~> 2.0"},

# Test dependencies
{:mishras, "~> 0.1", only: :test},
{:faker, "~> 0.18", only: :test},

# Tailscale (may already be in nerves_pack)
# Check nerves_pack documentation
```

## Architectural Guidelines

This project follows domain-driven design principles adapted from the techo project architecture.

### Directory Structure

```
lib/
├── boxfan/                       # Application context (business logic)
│   ├── application.ex             # OTP application supervisor tree
│   ├── fan_controller.ex          # Fan control GenServer (relay logic)
│   ├── bme680_sensor.ex           # BME680 sensor GenServer (I2C sampling)
│   └── scheduler.ex               # Scheduling GenServer (periodic ventilation)
├── data/                          # Data layer (schemas and repo)
│   ├── repo.ex                    # Ecto repository
│   ├── event.ex                   # Event schema
│   └── sensor_reading.ex          # SensorReading schema
├── web/                           # Web layer (Phoenix components)
│   ├── endpoint.ex                # Phoenix endpoint configuration
│   ├── router.ex                  # Application routing
│   ├── layouts.ex                 # Layout components
│   ├── dashboard/
│   │   ├── live.ex                # Main dashboard LiveView
│   │   └── live_test.exs
│   └── components/
│       └── core.ex                # Reusable UI components
└── boxfan.ex                      # Main module
```

### Key Architectural Principles

#### 1. Domain-Driven Design
- **Contexts** group related functionality (`Boxfan.FanController`, `Boxfan.BME680Sensor`, `Boxfan.Scheduler`)
- **Schemas** define data structures (`Data.Event`, `Data.SensorReading`)
- **Business logic** stays in context modules (GenServers), not LiveViews
- **LiveViews** handle only presentation and user interaction

#### 2. Colocated Testing
- Tests live next to the code they test
- Example: `live.ex` and `live_test.exs` in same directory
- Easier to maintain and discover tests

#### 3. GenServer-Based Controllers
- `Boxfan.FanController` manages relay state and mutual exclusion
- `Boxfan.BME680Sensor` polls I2C sensor every 60s, stores readings, purges old data
- `Boxfan.Scheduler` handles periodic ventilation using Process.send_after
- State management centralized in GenServers
- LiveView subscribes to GenServer updates via PubSub

#### 4. Data Layer Separation
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

```elixir
# lib/data/event.ex
defmodule Data.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :relay_number, :integer  # 1, 2, or 3
    field :action, :string         # "on" or "off"
    field :source, :string         # "manual" or "automatic"

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:relay_number, :action, :source])
    |> validate_required([:relay_number, :action, :source])
    |> validate_inclusion(:relay_number, [1, 2, 3])
    |> validate_inclusion(:action, ["on", "off"])
    |> validate_inclusion(:source, ["manual", "automatic"])
  end
end

# lib/data/sensor_reading.ex
defmodule Data.SensorReading do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sensor_readings" do
    field :temperature, :float      # Celsius
    field :humidity, :float         # Percentage
    field :pressure, :float         # hPa
    field :gas_resistance, :float   # Ohms

    timestamps(type: :utc_datetime)
  end

  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:temperature, :humidity, :pressure, :gas_resistance])
    |> validate_required([:temperature, :humidity, :pressure, :gas_resistance])
  end
end
```

### FanController GenServer Pattern

```elixir
defmodule Boxfan.FanController do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def set_speed(speed), do: GenServer.call(__MODULE__, {:set_speed, speed})
  def get_state(), do: GenServer.call(__MODULE__, :get_state)

  # Server Callbacks
  def init(opts) do
    state = %{
      current_relay: nil,
      pins: Keyword.fetch!(opts, :relay_pins)
    }
    {:ok, state}
  end

  def handle_call({:set_speed, speed}, _from, state) do
    # Mutual exclusion logic
    # Turn off current relay if any
    # Turn on new relay if speed > 0
    # Log event to database
    # Broadcast state change via PubSub
    {:reply, :ok, new_state}
  end
end
```

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

To test hardware-dependent code without physical devices, we use a behavior-based mocking approach:

#### GPIO Mocking (Relay Control)

**Behavior Definition:**
```elixir
defmodule Boxfan.GPIOBehaviour do
  @callback open(pin :: non_neg_integer(), direction :: :input | :output) ::
    {:ok, reference()} | {:error, term()}
  @callback write(ref :: reference(), value :: 0 | 1) :: :ok | {:error, term()}
  @callback close(ref :: reference()) :: :ok
end
```

**Mock Implementation** (`support/mocks/gpio_mock.ex`):
```elixir
defmodule Boxfan.GPIOMock do
  @behaviour Boxfan.GPIOBehaviour

  # Use Agent to track state for assertions in tests
  def start_link do
    Agent.start_link(fn -> %{pins: %{}, writes: []} end, name: __MODULE__)
  end

  def open(pin, direction) do
    ref = make_ref()
    Agent.update(__MODULE__, fn state ->
      put_in(state, [:pins, ref], %{pin: pin, direction: direction, value: nil})
    end)
    {:ok, ref}
  end

  def write(ref, value) do
    Agent.update(__MODULE__, fn state ->
      state
      |> put_in([:pins, ref, :value], value)
      |> update_in([:writes], &[{ref, value, DateTime.utc_now()} | &1])
    end)
    :ok
  end

  def close(ref) do
    Agent.update(__MODULE__, fn state ->
      update_in(state, [:pins], &Map.delete(&1, ref))
    end)
    :ok
  end

  # Test helpers
  def get_pin_value(ref) do
    Agent.get(__MODULE__, fn state ->
      get_in(state, [:pins, ref, :value])
    end)
  end

  def get_write_history do
    Agent.get(__MODULE__, fn state -> Enum.reverse(state.writes) end)
  end

  def reset do
    Agent.update(__MODULE__, fn _state -> %{pins: %{}, writes: []} end)
  end
end
```

**Real Implementation Wrapper** (`lib/boxfan/gpio_adapter.ex`):
```elixir
defmodule Boxfan.GPIOAdapter do
  @behaviour Boxfan.GPIOBehaviour

  def open(pin, direction), do: Circuits.GPIO.open(pin, direction)
  def write(ref, value), do: Circuits.GPIO.write(ref, value)
  def close(ref), do: Circuits.GPIO.close(ref)
end
```

#### I2C Mocking (BME680 Sensor)

**Behavior Definition:**
```elixir
defmodule Boxfan.I2CBehaviour do
  @callback open(bus_name :: String.t()) :: {:ok, reference()} | {:error, term()}
  @callback write_read(ref :: reference(), address :: non_neg_integer(),
                       write_data :: binary(), bytes_to_read :: non_neg_integer()) ::
    {:ok, binary()} | {:error, term()}
  @callback close(ref :: reference()) :: :ok
end
```

**Mock Implementation** (`support/mocks/i2c_mock.ex`):
```elixir
defmodule Boxfan.I2CMock do
  @behaviour Boxfan.I2CBehaviour

  def start_link do
    # Default mock sensor readings
    default_readings = %{
      temperature: 22.5,
      humidity: 45.0,
      pressure: 1013.25,
      gas_resistance: 50_000.0
    }
    Agent.start_link(fn -> %{readings: default_readings, read_count: 0} end,
                     name: __MODULE__)
  end

  def open(_bus_name) do
    {:ok, make_ref()}
  end

  def write_read(_ref, _address, _write_data, _bytes_to_read) do
    # Simulate BME680 sensor response
    Agent.get_and_update(__MODULE__, fn state ->
      readings = state.readings

      # Encode mock data (simplified - real BME680 has complex register layout)
      data = encode_bme680_data(readings)

      new_state = update_in(state, [:read_count], &(&1 + 1))
      {{:ok, data}, new_state}
    end)
  end

  def close(_ref), do: :ok

  # Test helpers
  def set_readings(readings) do
    Agent.update(__MODULE__, fn state ->
      put_in(state, [:readings], Map.merge(state.readings, readings))
    end)
  end

  def get_read_count do
    Agent.get(__MODULE__, fn state -> state.read_count end)
  end

  def reset do
    default_readings = %{
      temperature: 22.5,
      humidity: 45.0,
      pressure: 1013.25,
      gas_resistance: 50_000.0
    }
    Agent.update(__MODULE__, fn _state ->
      %{readings: default_readings, read_count: 0}
    end)
  end

  defp encode_bme680_data(readings) do
    # Simplified encoding - real BME680 has complex calibration
    <<
      trunc(readings.temperature * 100)::16,
      trunc(readings.humidity * 100)::16,
      trunc(readings.pressure * 100)::32,
      trunc(readings.gas_resistance)::32
    >>
  end
end
```

**Real Implementation Wrapper** (`lib/boxfan/i2c_adapter.ex`):
```elixir
defmodule Boxfan.I2CAdapter do
  @behaviour Boxfan.I2CBehaviour

  def open(bus_name), do: Circuits.I2C.open(bus_name)
  def write_read(ref, address, write_data, bytes_to_read),
    do: Circuits.I2C.write_read(ref, address, write_data, bytes_to_read)
  def close(ref), do: Circuits.I2C.close(ref)
end
```

#### Configuration-Based Module Selection

**In config/test.exs:**
```elixir
config :boxfan, :gpio_module, Boxfan.GPIOMock
config :boxfan, :i2c_module, Boxfan.I2CMock
```

**In config/target.exs:**
```elixir
config :boxfan, :gpio_module, Boxfan.GPIOAdapter
config :boxfan, :i2c_module, Boxfan.I2CAdapter
```

**In production code:**
```elixir
defmodule Boxfan.FanController do
  @gpio_module Application.compile_env(:boxfan, :gpio_module)

  def init(opts) do
    pins = Keyword.fetch!(opts, :relay_pins)

    # Open GPIO pins using configured module
    refs = Enum.map(pins, fn {relay, pin} ->
      {:ok, ref} = @gpio_module.open(pin, :output)
      # Set HIGH initially (relays off - Active LOW)
      @gpio_module.write(ref, 1)
      {relay, {pin, ref}}
    end)

    {:ok, %{pins: Map.new(refs), current_relay: nil}}
  end
end
```

#### Test Usage Examples

**Testing FanController with GPIO mock:**
```elixir
defmodule Boxfan.FanControllerTest do
  use ExUnit.Case, async: false

  alias Boxfan.FanController
  alias Boxfan.GPIOMock

  setup do
    start_supervised!(GPIOMock)
    GPIOMock.reset()
    :ok
  end

  test "sets relay 1 on by writing LOW to GPIO 26" do
    {:ok, pid} = FanController.start_link(relay_pins: %{1 => 26, 2 => 20, 3 => 21})

    FanController.set_speed(1)

    # Check that GPIO mock received LOW (0) for pin 26
    history = GPIOMock.get_write_history()
    assert {_ref, 0, _timestamp} = List.last(history)
  end
end
```

**Testing BME680Sensor with I2C mock:**
```elixir
defmodule Boxfan.BME680SensorTest do
  use ExUnit.Case, async: false

  alias Boxfan.BME680Sensor
  alias Boxfan.I2CMock

  setup do
    start_supervised!(I2CMock)
    I2CMock.reset()
    :ok
  end

  test "reads temperature from sensor" do
    I2CMock.set_readings(%{temperature: 25.5})

    reading = BME680Sensor.read_sensor()

    assert reading.temperature == 25.5
    assert I2CMock.get_read_count() > 0
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
    1 => 26,  # GPIO pin for relay 1 (CH1, Pin 37) - Active LOW
    2 => 20,  # GPIO pin for relay 2 (CH2, Pin 38) - Active LOW
    3 => 21   # GPIO pin for relay 3 (CH3, Pin 40) - Active LOW
  }

config :boxfan, Boxfan.BME680Sensor,
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
