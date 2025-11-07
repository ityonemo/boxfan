defmodule Boxfan.FanController do
  @moduledoc """
  GenServer that controls the fan relay board.

  Manages mutual exclusion of relays (only one active at a time),
  logs all events to the database, and broadcasts state changes via PubSub.
  """

  use GenServer
  require Logger

  alias Data.Event
  alias Data.Repo

  @gpio Application.compile_env!(:boxfan, :gpio)

  # 1. BOILERPLATE & INITIALIZATION

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    relay_pins = Keyword.fetch!(opts, :relay_pins)

    # Open GPIO pins and initialize all relays to OFF (LOW - Active HIGH)
    refs =
      Enum.map(relay_pins, fn {relay, pin} ->
        {:ok, ref} = @gpio.open(pin, :output)
        # Set LOW initially (relays off - Active HIGH)
        @gpio.write(ref, 0)
        {relay, {pin, ref}}
      end)

    state = %{
      pins: Map.new(refs),
      current_relay: nil
    }

    {:ok, state}
  end

  # 2. API + IMPLEMENTATIONS

  @spec set_relay(relay :: 0..3) :: :ok
  def set_relay(relay) when relay in 0..3 do
    GenServer.call(__MODULE__, {:set_relay, relay, "manual"})
  end

  @spec set_relay_automatic(relay :: 0..3) :: :ok
  def set_relay_automatic(relay) when relay in 0..3 do
    GenServer.call(__MODULE__, {:set_relay, relay, "automatic"})
  end

  defp set_relay_impl(relay, source, _from, state) do
    new_state =
      state
      |> turn_off_current_relay(source)
      |> turn_on_relay(relay, source)

    {:reply, :ok, new_state}
  end

  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  defp get_state_impl(_from, state) do
    {:reply, state, state}
  end

  # 3. HELPER FUNCTIONS

  defp turn_off_current_relay(%{current_relay: nil} = state, _source), do: state

  defp turn_off_current_relay(%{current_relay: relay} = state, source) do
    {_pin, ref} = state.pins[relay]
    # LOW = OFF (Active HIGH)
    @gpio.write(ref, 0)

    log_event(relay, "off", source)
    broadcast_state_change(%{state | current_relay: nil})

    %{state | current_relay: nil}
  end

  defp turn_on_relay(state, 0, _source), do: state

  defp turn_on_relay(state, relay, source) when relay in 1..3 do
    {_pin, ref} = state.pins[relay]
    # HIGH = ON (Active HIGH)
    @gpio.write(ref, 1)

    log_event(relay, "on", source)
    new_state = %{state | current_relay: relay}
    broadcast_state_change(new_state)

    new_state
  end

  defp log_event(relay_number, action, source) do
    attrs = %{
      relay_number: relay_number,
      action: action,
      source: source
    }

    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  defp broadcast_state_change(state) do
    Phoenix.PubSub.broadcast(
      Boxfan.PubSub,
      "fan_controller",
      {:fan_state_changed, state}
    )

    state
  end

  # 4. ROUTER

  def handle_call({:set_relay, relay, source}, from, state) do
    set_relay_impl(relay, source, from, state)
  end

  def handle_call(:get_state, from, state) do
    get_state_impl(from, state)
  end
end
