defmodule Boxfan.Scheduler do
  @moduledoc """
  GenServer that manages periodic automatic ventilation.

  Turns on the fan at speed 1 at regular intervals for a specified duration.
  """

  use GenServer
  require Logger

  alias Boxfan.FanController

  # 1. BOILERPLATE & INITIALIZATION

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    ventilation_interval = Keyword.fetch!(opts, :ventilation_interval)
    ventilation_duration = Keyword.fetch!(opts, :ventilation_duration)

    # Schedule immediate first ventilation cycle (with a small delay to allow app to fully start)
    schedule_ventilation(1000)

    # Calculate when next cycle will occur (from when first cycle starts + interval)
    first_cycle_time = DateTime.add(DateTime.utc_now(), 1000, :millisecond)
    next_cycle_at = DateTime.add(first_cycle_time, ventilation_interval, :millisecond)

    state = %{
      ventilation_interval: ventilation_interval,
      ventilation_duration: ventilation_duration,
      ventilating: false,
      next_cycle_at: next_cycle_at
    }

    {:ok, state}
  end

  # 2. API + IMPLEMENTATIONS

  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  defp get_state_impl(_from, state) do
    {:reply, state, state}
  end

  @spec get_next_cycle_time() :: DateTime.t()
  def get_next_cycle_time do
    GenServer.call(__MODULE__, :get_next_cycle_time)
  end

  defp get_next_cycle_time_impl(_from, state) do
    {:reply, state.next_cycle_at, state}
  end

  # Handle starting ventilation
  defp start_ventilation_impl(state) do
    Logger.info("Starting automatic ventilation")

    # Turn on fan at relay 1 (slowest speed)
    FanController.set_relay_automatic(1)

    # Schedule turning it off
    schedule_stop_ventilation(state.ventilation_duration)

    # Calculate when next ventilation will occur
    next_cycle_at = DateTime.add(DateTime.utc_now(), state.ventilation_interval, :millisecond)

    # Schedule next ventilation cycle
    schedule_ventilation(state.ventilation_interval)

    {:noreply, %{state | ventilating: true, next_cycle_at: next_cycle_at}}
  end

  # Handle stopping ventilation
  defp stop_ventilation_impl(state) do
    Logger.info("Stopping automatic ventilation")

    # Turn off fan (relay 0)
    FanController.set_relay_automatic(0)

    {:noreply, %{state | ventilating: false}}
  end

  # 3. HELPER FUNCTIONS

  defp schedule_ventilation(interval) do
    Process.send_after(self(), :start_ventilation, interval)
  end

  defp schedule_stop_ventilation(duration) do
    Process.send_after(self(), :stop_ventilation, duration)
  end

  # 4. ROUTER

  def handle_call(:get_state, from, state) do
    get_state_impl(from, state)
  end

  def handle_call(:get_next_cycle_time, from, state) do
    get_next_cycle_time_impl(from, state)
  end

  def handle_info(:start_ventilation, state) do
    start_ventilation_impl(state)
  end

  def handle_info(:stop_ventilation, state) do
    stop_ventilation_impl(state)
  end
end
