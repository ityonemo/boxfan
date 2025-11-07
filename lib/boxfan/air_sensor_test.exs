defmodule Boxfan.AirSensorTest do
  use ExUnit.Case, async: false

  alias Boxfan.AirSensor
  alias Boxfan.Bme680Mock
  alias Data.Repo
  alias Data.SensorReading

  # Allow Bme680Mock to be called from AirSensor process
  setup do
    Mox.set_mox_global()
    :ok
  end

  setup do
    # Checkout the database sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    # Create tables
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

    # Stub default sensor readings - allow unlimited calls
    Mox.stub(Bme680Mock, :measure, fn _name ->
      %Bme680.Measurement{
        temperature: 22.5,
        humidity: 45.0,
        pressure: 1013.25,
        gas_resistance: 50_000
      }
    end)

    Mox.allow(Bme680Mock, self(), fn -> Process.whereis(AirSensor) end)

    # Start the AirSensor
    config = [
      # Short interval for testing
      sample_interval: 100,
      data_retention_days: 30
    ]

    {:ok, sensor_pid} = start_supervised({AirSensor, config})

    # Allow sensor to use the database
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), sensor_pid)

    :ok
  end

  describe "initialization" do
    test "initializes successfully" do
      # If we got here, initialization succeeded
      state = AirSensor.get_state()
      assert state.sample_interval == 100
      assert state.data_retention_days == 30
    end
  end

  describe "read_current/0" do
    test "returns cached sensor readings" do
      # Stub specific readings for this test
      Mox.stub(Bme680Mock, :measure, fn _name ->
        %Bme680.Measurement{
          temperature: 25.5,
          humidity: 50.0,
          pressure: 1015.0,
          gas_resistance: 60_000
        }
      end)

      # Trigger a sample to populate the cache
      send(Process.whereis(AirSensor), :sample)
      Process.sleep(50)

      reading = AirSensor.read_current()

      assert reading.temperature == 25.5
      assert reading.humidity == 50.0
      assert reading.pressure == 101.5
      assert reading.gas_resistance == 60_000
    end

    test "returns nil if no reading cached yet" do
      # read_current should return nil before first sample
      reading = AirSensor.read_current()
      assert reading == nil
    end
  end

  describe "automatic sampling" do
    test "samples and stores readings automatically" do
      # Stub specific readings for this test
      Mox.stub(Bme680Mock, :measure, fn _name ->
        %Bme680.Measurement{
          temperature: 22.0,
          humidity: 45.0,
          pressure: 1013.0,
          gas_resistance: 55_000
        }
      end)

      # Trigger a sample manually
      send(Process.whereis(AirSensor), :sample)

      # Give it a moment to process
      Process.sleep(50)

      readings = Repo.all(SensorReading)
      assert length(readings) == 1

      reading = List.first(readings)
      assert reading.temperature == 22.0
      assert reading.humidity == 45.0
    end
  end

  describe "purge_old_readings/1" do
    test "deletes readings older than retention period" do
      # Insert old readings (35 days ago)
      old_date = DateTime.utc_now() |> DateTime.add(-35, :day) |> DateTime.truncate(:second)

      Repo.insert!(%SensorReading{
        temperature: 20.0,
        humidity: 40.0,
        pressure: 1010.0,
        gas_resistance: 50_000.0,
        inserted_at: old_date,
        updated_at: old_date
      })

      # Insert recent reading
      Repo.insert!(%SensorReading{
        temperature: 25.0,
        humidity: 50.0,
        pressure: 1015.0,
        gas_resistance: 55_000.0
      })

      # Purge with 30 day retention
      AirSensor.purge_old_readings(30)

      readings = Repo.all(SensorReading)
      assert length(readings) == 1
      assert List.first(readings).temperature == 25.0
    end
  end
end
