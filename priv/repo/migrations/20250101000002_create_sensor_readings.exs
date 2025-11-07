defmodule Data.Repo.Migrations.CreateSensorReadings do
  use Ecto.Migration

  def change do
    create table(:sensor_readings) do
      add :temperature, :float, null: false
      add :humidity, :float, null: false
      add :pressure, :float, null: false
      add :gas_resistance, :float, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:sensor_readings, [:inserted_at])
  end
end
