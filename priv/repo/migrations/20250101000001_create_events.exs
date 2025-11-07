defmodule Data.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :relay_number, :integer, null: false
      add :action, :string, null: false
      add :source, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:inserted_at])
  end
end
