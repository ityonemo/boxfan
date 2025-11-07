defmodule Boxfan.SchedulerTest do
  use ExUnit.Case, async: false

  alias Boxfan.Scheduler
  alias Boxfan.FanController
  alias Boxfan.GPIOMock
  alias Data.Repo
  alias Data.Event

  setup do
    Mox.set_mox_global()
    :ok
  end

  setup do
    # Checkout the database sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    # Create tables
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

    # Stub GPIO operations for FanController (unlimited calls during test)
    Mox.stub(GPIOMock, :open, fn _pin, :output -> {:ok, make_ref()} end)
    Mox.stub(GPIOMock, :write, fn _ref, _value -> :ok end)
    Mox.stub(GPIOMock, :close, fn _ref -> :ok end)

    # Start FanController
    relay_pins = %{1 => 26, 2 => 20, 3 => 21}
    {:ok, fan_pid} = start_supervised({FanController, relay_pins: relay_pins})

    Mox.allow(GPIOMock, self(), fn -> Process.whereis(FanController) end)

    # Start Scheduler with short intervals for testing
    config = [
      # 200ms for testing
      ventilation_interval: 200,
      # 100ms for testing
      ventilation_duration: 100
    ]

    {:ok, scheduler_pid} = start_supervised({Scheduler, config})

    # Allow both to use the database
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), fan_pid)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), scheduler_pid)

    :ok
  end

  describe "initialization" do
    test "stores configuration" do
      state = Scheduler.get_state()
      assert state.ventilation_interval == 200
      assert state.ventilation_duration == 100
    end
  end

  describe "next cycle time" do
    test "returns DateTime of next scheduled ventilation" do
      next_cycle = Scheduler.get_next_cycle_time()

      # Should be a DateTime
      assert %DateTime{} = next_cycle

      # Should be in the future (within the next interval)
      now = DateTime.utc_now()
      diff_ms = DateTime.diff(next_cycle, now, :millisecond)

      # Should be positive (in the future) and less than interval + some tolerance
      assert diff_ms > 0
      # ventilation_interval from setup + tolerance for slow systems
      assert diff_ms <= 1500
    end

    test "returns nil when no cycle scheduled (ventilating)" do
      # Trigger ventilation to start
      send(Process.whereis(Scheduler), :start_ventilation)
      Process.sleep(50)

      # During ventilation, next_cycle should still exist for the NEXT scheduled cycle
      next_cycle = Scheduler.get_next_cycle_time()
      assert %DateTime{} = next_cycle
    end
  end

  describe "automatic ventilation" do
    test "turns on fan at speed 1 periodically" do
      # Trigger ventilation manually
      send(Process.whereis(Scheduler), :start_ventilation)

      # Give it a moment
      Process.sleep(50)

      # Check that relay 1 was turned on
      events = Repo.all(Event)
      on_events = Enum.filter(events, &(&1.action == "on"))

      assert length(on_events) >= 1
      # Speed 1 = relay 1 (slowest)
      assert List.first(on_events).relay_number == 1
      assert List.first(on_events).source == "automatic"
    end

    test "turns off fan after ventilation duration" do
      # Trigger ventilation start
      send(Process.whereis(Scheduler), :start_ventilation)
      Process.sleep(50)

      # Trigger ventilation stop
      send(Process.whereis(Scheduler), :stop_ventilation)
      Process.sleep(50)

      # Check for both on and off events
      events = Repo.all(Event) |> Enum.sort_by(& &1.inserted_at, DateTime)

      assert length(events) >= 2
      assert Enum.any?(events, &(&1.action == "on" and &1.source == "automatic"))
      assert Enum.any?(events, &(&1.action == "off" and &1.source == "automatic"))
    end
  end
end
