defmodule Boxfan.AirSensor do
  @moduledoc """
  GenServer that reads from the BME680 sensor and logs readings to the database.

  Samples temperature, humidity, pressure, and gas resistance at regular intervals,
  stores readings in the database, and manages data retention.
  """

  use GenServer
  require Logger

  import Ecto.Query

  alias Data.Repo
  alias Data.SensorReading

  # 1. BOILERPLATE & INITIALIZATION

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    sample_interval = Keyword.get(opts, :sample_interval, :timer.seconds(60))
    data_retention_days = Keyword.get(opts, :data_retention_days, 30)

    # Schedule first sample
    schedule_sample(sample_interval)

    state = %{
      sample_interval: sample_interval,
      data_retention_days: data_retention_days,
      last_reading: nil
    }

    {:ok, state}
  end

  # 2. API + IMPLEMENTATIONS

  @spec read_current() :: map()
  def read_current do
    GenServer.call(__MODULE__, :read_current)
  end

  defp read_current_impl(_from, state) do
    # Return cached reading - don't trigger a new I2C read
    {:reply, state.last_reading, state}
  end

  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  defp get_state_impl(_from, state) do
    {:reply, state, state}
  end

  @spec purge_old_readings(days :: pos_integer()) :: :ok
  def purge_old_readings(days) do
    GenServer.call(__MODULE__, {:purge_old_readings, days})
  end

  defp purge_old_readings_impl(days, _from, state) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    {count, _} =
      Repo.delete_all(from(r in SensorReading, where: r.inserted_at < ^cutoff_date))

    Logger.info("Purged #{count} old sensor readings (older than #{days} days)")

    {:reply, :ok, state}
  end

  # Handle automatic sampling
  defp sample_impl(state) do
    reading = read_sensor(state)

    # Only store/broadcast if read was successful
    if reading do
      store_reading(reading)
      broadcast_reading(reading)
    end

    # Periodically purge old data (every hour)
    if rem(:erlang.system_time(:second), 3600) < state.sample_interval / 1000 do
      purge_old_data(state.data_retention_days)
    end

    # Schedule next sample
    schedule_sample(state.sample_interval)

    # Update last_reading with new value (or keep old value if read failed)
    new_state = if reading, do: %{state | last_reading: reading}, else: state
    {:noreply, new_state}
  end

  defp purge_old_data(days) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    {count, _} =
      Repo.delete_all(from(r in SensorReading, where: r.inserted_at < ^cutoff_date))

    Logger.info("Purged #{count} old sensor readings (older than #{days} days)")
  end

  # 3. HELPER FUNCTIONS

  @bme680 Application.compile_env!(:boxfan, :bme680)

  defp read_sensor(_state) do
    # Use the configured BME680 module to read sensor data
    # Always called with the registered name (Boxfan.Bme680)
    # The module is determined by config: Bme680 (prod), Host.Bme680 (dev), or Bme680Mock (test)
    measurement = @bme680.measure(Boxfan.Bme680)

    # Check if we got valid readings (gas_resistance can be nil during warmup)
    if measurement.temperature && measurement.humidity && measurement.pressure do
      %{
        temperature: measurement.temperature,
        humidity: measurement.humidity,
        pressure: measurement.pressure / 10.0,
        gas_resistance: measurement.gas_resistance || 0.0
      }
    else
      Logger.warning("BME680 sensor not ready yet: #{inspect(measurement)}")
      nil
    end
  end

  defp store_reading(reading) do
    attrs = %{
      temperature: reading.temperature,
      humidity: reading.humidity,
      pressure: reading.pressure,
      gas_resistance: reading.gas_resistance
    }

    %SensorReading{}
    |> SensorReading.changeset(attrs)
    |> Repo.insert()
  end

  defp broadcast_reading(reading) do
    Phoenix.PubSub.broadcast(
      Boxfan.PubSub,
      "air_sensor",
      {:sensor_reading, reading}
    )
  end

  defp schedule_sample(interval) do
    Process.send_after(self(), :sample, interval)
  end

  # 4. ROUTER

  def handle_call(:read_current, from, state) do
    read_current_impl(from, state)
  end

  def handle_call(:get_state, from, state) do
    get_state_impl(from, state)
  end

  def handle_call({:purge_old_readings, days}, from, state) do
    purge_old_readings_impl(days, from, state)
  end

  def handle_info(:sample, state) do
    sample_impl(state)
  end
end
