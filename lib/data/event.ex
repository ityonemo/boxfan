defmodule Data.Event do
  use Ecto.Schema
  alias Ecto.Changeset

  schema "events" do
    field(:relay_number, :integer)
    field(:action, :string)
    field(:source, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> Changeset.cast(attrs, [:relay_number, :action, :source])
    |> Changeset.validate_required([:relay_number, :action, :source])
    |> Changeset.validate_inclusion(:relay_number, [1, 2, 3])
    |> Changeset.validate_inclusion(:action, ["on", "off"])
    |> Changeset.validate_inclusion(:source, ["manual", "automatic"])
  end
end
