defmodule Host.Bme680 do
  @moduledoc """
  Host implementation of BME680 sensor for development.

  Returns random simulated sensor data without maintaining state.
  This is a stateless module that doesn't need to be supervised.
  """

  require Logger

  @behaviour Boxfan.Bme680Behaviour

  @impl true
  def measure(name) when is_atom(name) do
    # Generate random sensor readings with realistic ranges
    # Temperature: 18-26°C
    # Humidity: 35-55%
    # Pressure: 1000-1025 hPa
    # Gas resistance: 40,000-60,000 Ω

    measurement = %Bme680.Measurement{
      temperature: 18.0 + :rand.uniform() * 8.0,
      humidity: 35.0 + :rand.uniform() * 20.0,
      pressure: 1000.0 + :rand.uniform() * 25.0,
      gas_resistance: trunc(40_000 + :rand.uniform() * 20_000)
    }

    Logger.debug(
      "Host.Bme680 (#{name}): Measured #{Float.round(measurement.temperature, 1)}°C, " <>
        "#{Float.round(measurement.humidity, 1)}%, " <>
        "#{Float.round(measurement.pressure, 1)}hPa, " <>
        "#{measurement.gas_resistance}Ω"
    )

    measurement
  end
end
