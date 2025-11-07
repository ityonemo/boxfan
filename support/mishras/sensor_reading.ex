defimpl Mishras.Factory, for: Data.SensorReading do
  @moduledoc false
  use Mishras

  def build_map(_mode, _attrs) do
    %{
      temperature: 15.0 + :rand.uniform() * 20.0,    # 15-35°C
      humidity: 30.0 + :rand.uniform() * 40.0,       # 30-70%
      pressure: 990.0 + :rand.uniform() * 40.0,      # 990-1030 hPa
      gas_resistance: 10_000.0 + :rand.uniform() * 90_000.0  # 10k-100k Ω
    }
  end
end
