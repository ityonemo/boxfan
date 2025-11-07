defmodule Boxfan.Bme680Behaviour do
  @moduledoc """
  Behaviour for BME680 sensor library to enable testing with mocks.

  Implementations must provide a measure/1 function that returns sensor readings.
  The measure function is always called with the registered name (Boxfan.Bme680).
  Each implementation handles its own start_link/1 according to its needs.
  """

  @callback measure(name :: atom()) :: Bme680.Measurement.t()
end
