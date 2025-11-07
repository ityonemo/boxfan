defmodule Boxfan.FanControllerTest do
  use ExUnit.Case, async: false

  alias Boxfan.FanController
  alias Boxfan.GPIOMock
  alias Data.Event
  alias Data.Repo

  # Allow GPIOMock to be called from FanController process
  setup do
    Mox.set_mox_global()
    :ok
  end

  setup do
    # Checkout the database sandbox for this test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    # Create tables manually for in-memory database
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      relay_number INTEGER NOT NULL,
      action TEXT NOT NULL,
      source TEXT NOT NULL,
      inserted_at DATETIME NOT NULL,
      updated_at DATETIME NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS sensor_readings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      temperature REAL NOT NULL,
      humidity REAL NOT NULL,
      pressure REAL NOT NULL,
      gas_resistance REAL NOT NULL,
      inserted_at DATETIME NOT NULL,
      updated_at DATETIME NOT NULL
    )
    """)

    # Stub GPIO operations for all tests (unlimited calls)
    Mox.stub(GPIOMock, :open, fn _pin, :output -> {:ok, make_ref()} end)
    Mox.stub(GPIOMock, :write, fn _ref, _value -> :ok end)
    Mox.stub(GPIOMock, :close, fn _ref -> :ok end)

    # Start the FanController with test configuration
    relay_pins = %{1 => 26, 2 => 20, 3 => 21}
    {:ok, fan_pid} = start_supervised({FanController, relay_pins: relay_pins})

    # Allow FanController process to use the GPIOMock
    Mox.allow(GPIOMock, self(), fn -> Process.whereis(FanController) end)

    # Allow FanController to use the database
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), fan_pid)

    :ok
  end

  describe "initialization" do
    test "initializes with no relay active" do
      state = FanController.get_state()
      assert state.current_relay == nil
    end
  end

  describe "set_relay/1" do
    test "sets relay 1 on" do
      FanController.set_relay(1)

      state = FanController.get_state()
      assert state.current_relay == 1
    end

    test "relay 0 turns off all relays" do
      FanController.set_relay(2)
      FanController.set_relay(0)

      state = FanController.get_state()
      assert state.current_relay == nil
    end

    test "logs event to database with manual source" do
      FanController.set_relay(1)

      events = Repo.all(Event)
      assert [on_event] = events
      assert on_event.relay_number == 1
      assert on_event.action == "on"
      assert on_event.source == "manual"
    end

    test "logs both off and on events when switching relays" do
      FanController.set_relay(1)
      FanController.set_relay(2)

      events = Repo.all(Event) |> Enum.sort_by(& &1.inserted_at, DateTime)

      assert length(events) == 3
      # relay 1 on
      assert Enum.at(events, 0).action == "on"
      # relay 1 off
      assert Enum.at(events, 1).action == "off"
      # relay 2 on
      assert Enum.at(events, 2).action == "on"
    end
  end

  describe "get_state/0" do
    test "returns current relay state" do
      FanController.set_relay(2)

      state = FanController.get_state()
      assert state.current_relay == 2
    end
  end
end
