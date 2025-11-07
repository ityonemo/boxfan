defmodule Data.SensorReadingTest do
  use Boxfan.DataCase, async: false

  alias Data.SensorReading

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        temperature: 22.5,
        humidity: 45.0,
        pressure: 1013.25,
        gas_resistance: 50_000.0
      }

      changeset = SensorReading.changeset(%SensorReading{}, attrs)
      assert changeset.valid?
    end

    test "requires temperature" do
      attrs = %{humidity: 45.0, pressure: 1013.25, gas_resistance: 50_000.0}
      changeset = SensorReading.changeset(%SensorReading{}, attrs)
      refute changeset.valid?
      assert %{temperature: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires humidity" do
      attrs = %{temperature: 22.5, pressure: 1013.25, gas_resistance: 50_000.0}
      changeset = SensorReading.changeset(%SensorReading{}, attrs)
      refute changeset.valid?
      assert %{humidity: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires pressure" do
      attrs = %{temperature: 22.5, humidity: 45.0, gas_resistance: 50_000.0}
      changeset = SensorReading.changeset(%SensorReading{}, attrs)
      refute changeset.valid?
      assert %{pressure: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires gas_resistance" do
      attrs = %{temperature: 22.5, humidity: 45.0, pressure: 1013.25}
      changeset = SensorReading.changeset(%SensorReading{}, attrs)
      refute changeset.valid?
      assert %{gas_resistance: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "for_time_range/1" do
    test "returns readings from last hour when :hour is specified" do
      now = DateTime.utc_now()

      # Insert reading from 30 minutes ago (should be included)
      recent_time = DateTime.add(now, -30, :minute)
      insert_reading(recent_time, 22.5, 45.0, 1013.25, 50_000.0)

      # Insert reading from 2 hours ago (should NOT be included)
      old_time = DateTime.add(now, -2, :hour)
      insert_reading(old_time, 20.0, 40.0, 1010.0, 48_000.0)

      readings = SensorReading.for_time_range(:hour)

      assert length(readings) == 1
      assert hd(readings).temperature == 22.5
    end

    test "returns readings from last day when :day is specified" do
      now = DateTime.utc_now()

      # Insert reading from 12 hours ago (should be included)
      recent_time = DateTime.add(now, -12, :hour)
      insert_reading(recent_time, 23.0, 50.0, 1015.0, 52_000.0)

      # Insert reading from 2 days ago (should NOT be included)
      old_time = DateTime.add(now, -2, :day)
      insert_reading(old_time, 19.0, 35.0, 1008.0, 45_000.0)

      readings = SensorReading.for_time_range(:day)

      assert length(readings) == 1
      assert hd(readings).temperature == 23.0
    end

    test "returns readings from last week when :week is specified" do
      now = DateTime.utc_now()

      # Insert reading from 3 days ago (should be included)
      recent_time = DateTime.add(now, -3, :day)
      insert_reading(recent_time, 21.0, 48.0, 1012.0, 51_000.0)

      # Insert reading from 10 days ago (should NOT be included)
      old_time = DateTime.add(now, -10, :day)
      insert_reading(old_time, 18.0, 38.0, 1005.0, 44_000.0)

      readings = SensorReading.for_time_range(:week)

      assert length(readings) == 1
      assert hd(readings).temperature == 21.0
    end

    test "returns readings from last month when :month is specified" do
      now = DateTime.utc_now()

      # Insert reading from 15 days ago (should be included)
      recent_time = DateTime.add(now, -15, :day)
      insert_reading(recent_time, 24.0, 55.0, 1018.0, 53_000.0)

      # Insert reading from 35 days ago (should NOT be included)
      old_time = DateTime.add(now, -35, :day)
      insert_reading(old_time, 17.0, 32.0, 1002.0, 42_000.0)

      readings = SensorReading.for_time_range(:month)

      assert length(readings) == 1
      assert hd(readings).temperature == 24.0
    end

    test "orders readings by timestamp ascending" do
      now = DateTime.utc_now()

      time1 = DateTime.add(now, -30, :minute)
      time2 = DateTime.add(now, -20, :minute)
      time3 = DateTime.add(now, -10, :minute)

      insert_reading(time2, 22.0, 46.0, 1013.0, 50_500.0)
      insert_reading(time1, 21.0, 45.0, 1012.0, 50_000.0)
      insert_reading(time3, 23.0, 47.0, 1014.0, 51_000.0)

      readings = SensorReading.for_time_range(:hour)

      assert length(readings) == 3
      assert Enum.at(readings, 0).temperature == 21.0
      assert Enum.at(readings, 1).temperature == 22.0
      assert Enum.at(readings, 2).temperature == 23.0
    end
  end

  defp insert_reading(inserted_at, temp, humidity, pressure, gas) do
    # Truncate datetime to remove microseconds for SQLite
    truncated_time = DateTime.truncate(inserted_at, :second)

    %SensorReading{}
    |> SensorReading.changeset(%{
      temperature: temp,
      humidity: humidity,
      pressure: pressure,
      gas_resistance: gas
    })
    |> Ecto.Changeset.put_change(:inserted_at, truncated_time)
    |> Ecto.Changeset.put_change(:updated_at, truncated_time)
    |> Data.Repo.insert!()
  end
end
