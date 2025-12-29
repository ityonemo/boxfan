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
    For :week and :month, samples every 5th and 20th reading respectively.
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
      where: sr.inserted_at >= ^cutoff_time and fragment("id % 5 = 0"),
      order_by: [asc: sr.inserted_at]
    )
    |> Data.Repo.all()
  end

  def for_time_range(:month) do
    cutoff_time = calculate_cutoff_time(:month)

    from(sr in __MODULE__,
      where: sr.inserted_at >= ^cutoff_time and fragment("id % 20 = 0"),
      order_by: [asc: sr.inserted_at]
    )
    |> Data.Repo.all()
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
end
