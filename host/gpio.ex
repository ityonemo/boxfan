defmodule Host.GPIO do
  @moduledoc """
  Host implementation of GPIO behavior for development.

  Tracks expected GPIO state in application environment and logs all operations.
  """

  require Logger

  @behaviour Boxfan.GPIOBehaviour

  # Client API matching Circuits.GPIO

  @impl true
  def open(pin, direction) do
    ref = make_ref()

    # Store pin state in application env
    pins = Application.get_env(:boxfan, :host_gpio_pins, %{})

    new_pins = Map.put(pins, ref, %{
      pin: pin,
      direction: direction,
      value: if(direction == :output, do: 1, else: 0)
    })

    Application.put_env(:boxfan, :host_gpio_pins, new_pins)

    Logger.debug("Host.GPIO: Opened pin #{pin} as #{direction} (ref: #{inspect(ref)})")

    {:ok, ref}
  end

  @impl true
  def write(ref, value) when value in [0, 1] do
    pins = Application.get_env(:boxfan, :host_gpio_pins, %{})

    case Map.get(pins, ref) do
      nil ->
        Logger.warning("Host.GPIO: Write to unknown ref #{inspect(ref)}")
        :ok

      pin_state ->
        new_pins = put_in(pins, [ref, :value], value)
        Application.put_env(:boxfan, :host_gpio_pins, new_pins)

        Logger.info("Host.GPIO: Pin #{pin_state.pin} = #{value} (#{if value == 0, do: "ON", else: "OFF"})")
        :ok
    end
  end

  @impl true
  def close(ref) do
    pins = Application.get_env(:boxfan, :host_gpio_pins, %{})

    case Map.get(pins, ref) do
      nil ->
        :ok

      pin_state ->
        new_pins = Map.delete(pins, ref)
        Application.put_env(:boxfan, :host_gpio_pins, new_pins)

        Logger.debug("Host.GPIO: Closed pin #{pin_state.pin}")
        :ok
    end
  end

  # Helper to get current pin states for debugging
  def get_pin_states do
    Application.get_env(:boxfan, :host_gpio_pins, %{})
  end
end
