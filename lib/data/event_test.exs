defmodule Data.EventTest do
  use Boxfan.DataCase, async: false

  alias Data.Event

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        relay_number: 1,
        action: "on",
        source: "manual"
      }

      changeset = Event.changeset(%Event{}, attrs)
      assert changeset.valid?
    end

    test "requires relay_number" do
      attrs = %{action: "on", source: "manual"}
      changeset = Event.changeset(%Event{}, attrs)
      refute changeset.valid?
      assert %{relay_number: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires action" do
      attrs = %{relay_number: 1, source: "manual"}
      changeset = Event.changeset(%Event{}, attrs)
      refute changeset.valid?
      assert %{action: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires source" do
      attrs = %{relay_number: 1, action: "on"}
      changeset = Event.changeset(%Event{}, attrs)
      refute changeset.valid?
      assert %{source: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates relay_number is 1, 2, or 3" do
      attrs = %{relay_number: 4, action: "on", source: "manual"}
      changeset = Event.changeset(%Event{}, attrs)
      refute changeset.valid?
      assert %{relay_number: ["is invalid"]} = errors_on(changeset)
    end

    test "validates action is 'on' or 'off'" do
      attrs = %{relay_number: 1, action: "invalid", source: "manual"}
      changeset = Event.changeset(%Event{}, attrs)
      refute changeset.valid?
      assert %{action: ["is invalid"]} = errors_on(changeset)
    end

    test "validates source is 'manual' or 'automatic'" do
      attrs = %{relay_number: 1, action: "on", source: "invalid"}
      changeset = Event.changeset(%Event{}, attrs)
      refute changeset.valid?
      assert %{source: ["is invalid"]} = errors_on(changeset)
    end
  end
end
