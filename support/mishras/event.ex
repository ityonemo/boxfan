defimpl Mishras.Factory, for: Data.Event do
  @moduledoc false
  use Mishras

  def build_map(_mode, _attrs) do
    %{
      relay_number: Enum.random([1, 2, 3]),
      action: Enum.random(["on", "off"]),
      source: Enum.random(["manual", "automatic"])
    }
  end
end
