defmodule Data.SensorReading do
  use Ecto.Schema
  import Ecto.Query
  alias Ecto.Changeset

  schema "sensor_readings" do
    field(:temperature, :float)
    field(:humidity, :float)
    field(:pressure, :float)
    field(:gas_resistance, :float)

    timestamps(type: :utc_datetime)
  end

  def changeset(reading, attrs) do
    reading
    |> Changeset.cast(attrs, [:temperature, :humidity, :pressure, :gas_resistance])
    |> Changeset.validate_required([:temperature, :humidity, :pressure, :gas_resistance])
  end

  @doc """
  Returns sensor readings for the specified time range.

  ## Parameters
    - time_range: :hour, :day, :week, or :month

  ## Returns
    List of sensor readings ordered by timestamp ascending.
    For :week and :month, readings are averaged in groups of 7 and 30 respectively.
  """
  @spec for_time_range(:hour | :day | :week | :month) :: [%__MODULE__{}]
  def for_time_range(time_range) when time_range in [:hour, :day] do
    cutoff_time = calculate_cutoff_time(time_range)

    from(sr in __MODULE__,
      where: sr.inserted_at >= ^cutoff_time,
      order_by: [asc: sr.inserted_at]
    )
    |> Data.Repo.all()
  end

  def for_time_range(:week) do
    cutoff_time = calculate_cutoff_time(:week)

    from(sr in __MODULE__,
      where: sr.inserted_at >= ^cutoff_time,
      order_by: [asc: sr.inserted_at]
    )
    |> Data.Repo.all()
    |> aggregate_readings(7)
  end

  def for_time_range(:month) do
    cutoff_time = calculate_cutoff_time(:month)

    from(sr in __MODULE__,
      where: sr.inserted_at >= ^cutoff_time,
      order_by: [asc: sr.inserted_at]
    )
    |> Data.Repo.all()
    |> aggregate_readings(30)
  end

  defp calculate_cutoff_time(:hour) do
    DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
  end

  defp calculate_cutoff_time(:day) do
    DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
  end

  defp calculate_cutoff_time(:week) do
    DateTime.utc_now() |> DateTime.add(-7, :day) |> DateTime.truncate(:second)
  end

  defp calculate_cutoff_time(:month) do
    DateTime.utc_now() |> DateTime.add(-30, :day) |> DateTime.truncate(:second)
  end

  defp aggregate_readings(readings, chunk_size) do
    readings
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunk ->
      # Average all metrics in the chunk
      count = length(chunk)

      avg_temperature = Enum.sum(Enum.map(chunk, & &1.temperature)) / count
      avg_humidity = Enum.sum(Enum.map(chunk, & &1.humidity)) / count
      avg_pressure = Enum.sum(Enum.map(chunk, & &1.pressure)) / count
      avg_gas_resistance = Enum.sum(Enum.map(chunk, & &1.gas_resistance)) / count

      # Use the first reading's timestamp as the representative timestamp
      first_reading = hd(chunk)

      %__MODULE__{
        id: first_reading.id,
        temperature: avg_temperature,
        humidity: avg_humidity,
        pressure: avg_pressure,
        gas_resistance: avg_gas_resistance,
        inserted_at: first_reading.inserted_at,
        updated_at: first_reading.updated_at
      }
    end)
  end
end
