defmodule Web.DashboardLive do
  use Phoenix.LiveView
  use Web.VerifiedRoutes

  import Ecto.Query

  alias Boxfan.FanController
  alias Boxfan.AirSensor
  alias Boxfan.Scheduler
  alias Data.Repo
  alias Data.Event
  alias Data.SensorReading

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Boxfan.PubSub, "fan_controller")
      Phoenix.PubSub.subscribe(Boxfan.PubSub, "air_sensor")

      # In host mode, schedule periodic refresh for GPIO state display
      if host_mode?() do
        schedule_host_refresh()
      end
    end

    next_cycle_time = Scheduler.get_next_cycle_time()

    socket =
      socket
      |> assign(:fan_state, get_fan_state())
      |> assign(:current_reading, get_current_reading())
      |> assign(:events, load_recent_events())
      |> assign(:time_range, "day")
      |> assign(:host_gpio_state, get_host_gpio_state())
      |> assign(:next_cycle_time, next_cycle_time)
      |> assign(:chart_time_range, :day)
      |> assign(:chart_metric, :temperature)
      |> assign(:chart_data, load_chart_data(:day))
      |> assign(:chart_fan_events, load_fan_events(:day))

    if connected?(socket) do
      schedule_next_cycle_refresh(next_cycle_time)
    end

    {:ok, socket}
  end

  def handle_event("set_relay", %{"relay" => relay_str}, socket) do
    relay = String.to_integer(relay_str)
    FanController.set_relay(relay)

    {:noreply, socket}
  end

  def handle_event("change_time_range", %{"range" => range}, socket) do
    {:noreply, assign(socket, :time_range, range)}
  end

  def handle_event("change_chart_time_range", %{"range" => range_str}, socket) do
    range = String.to_existing_atom(range_str)
    chart_data = load_chart_data(range)
    fan_events = load_fan_events(range)

    socket =
      socket
      |> assign(:chart_time_range, range)
      |> assign(:chart_data, chart_data)
      |> assign(:chart_fan_events, fan_events)

    {:noreply, socket}
  end

  def handle_event("change_chart_metric", %{"metric" => metric_str}, socket) do
    metric = String.to_existing_atom(metric_str)

    socket = assign(socket, :chart_metric, metric)

    {:noreply, socket}
  end

  def handle_info({:fan_state_changed, state}, socket) do
    socket =
      socket
      |> assign(:fan_state, state)
      |> assign(:events, load_recent_events())
      |> assign(:host_gpio_state, get_host_gpio_state())
      |> assign(:chart_fan_events, load_fan_events(socket.assigns.chart_time_range))

    {:noreply, socket}
  end

  def handle_info({:sensor_reading, reading}, socket) do
    # Reload chart data to include the new reading
    chart_data = load_chart_data(socket.assigns.chart_time_range)

    socket =
      socket
      |> assign(:current_reading, reading)
      |> assign(:chart_data, chart_data)

    {:noreply, socket}
  end

  def handle_info(:refresh_host_state, socket) do
    schedule_host_refresh()
    {:noreply, assign(socket, :host_gpio_state, get_host_gpio_state())}
  end

  def handle_info(:refresh_next_cycle, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  def render(assigns) do
    ~H"""
    <h1>Boxfan Control Dashboard</h1>

    <%= if host_mode?() do %>
      <div class="host-debug">
        <h3>🖥️ Host Mode Debug Info</h3>
        <%= render_host_gpio_state(@host_gpio_state) %>
      </div>
    <% end %>

    <div class="status">
      <div style="display: flex; gap: 40px; flex-wrap: wrap;">
        <div style="flex: 1; min-width: 300px;">
          <h2>Current Status</h2>
          <p><strong>Fan Speed:</strong> <%= fan_speed_text(@fan_state) %></p>
          <p><strong>Time till next cycling:</strong> <%= format_time_until(@next_cycle_time) %></p>
          <%= if @current_reading do %>
            <p><strong>Temperature:</strong> <%= Float.round(@current_reading.temperature, 1) %>°C</p>
            <p><strong>Humidity:</strong> <%= Float.round(@current_reading.humidity, 1) %>%</p>
            <p><strong>Pressure:</strong> <%= Float.round(@current_reading.pressure, 1) %> kPa</p>
            <p><strong>Gas Resistance:</strong> <%= trunc(@current_reading.gas_resistance) %> Ω</p>
          <% end %>
        </div>

        <div style="flex: 2; min-width: 300px; width: 100%;">
          <h2>Sensor Data Chart</h2>
          <div class="chart-controls" style="display: flex; align-items: center; gap: 20px; margin-bottom: 10px; flex-wrap: wrap;">
            <div class="metric-tabs" style="display: flex; gap: 5px; flex-wrap: wrap;">
              <button
                phx-click="change_chart_metric"
                phx-value-metric="temperature"
                style={"padding: 8px 16px; border: 2px solid #007bff; border-radius: 4px; #{if @chart_metric == :temperature, do: "background-color: #007bff; color: white; font-weight: bold;", else: "background-color: white; color: #007bff;"}"}
              >
                Temperature
              </button>
              <button
                phx-click="change_chart_metric"
                phx-value-metric="humidity"
                style={"padding: 8px 16px; border: 2px solid #007bff; border-radius: 4px; #{if @chart_metric == :humidity, do: "background-color: #007bff; color: white; font-weight: bold;", else: "background-color: white; color: #007bff;"}"}
              >
                Humidity
              </button>
              <button
                phx-click="change_chart_metric"
                phx-value-metric="gas_resistance"
                style={"padding: 8px 16px; border: 2px solid #007bff; border-radius: 4px; #{if @chart_metric == :gas_resistance, do: "background-color: #007bff; color: white; font-weight: bold;", else: "background-color: white; color: #007bff;"}"}
              >
                Gas
              </button>
            </div>

            <form phx-change="change_chart_time_range">
              <select name="range" style="padding: 6px 10px; border: 1px solid #ccc; border-radius: 4px;">
                <option value="hour" selected={@chart_time_range == :hour}>1 Hour</option>
                <option value="day" selected={@chart_time_range == :day}>1 Day</option>
                <option value="week" selected={@chart_time_range == :week}>1 Week</option>
                <option value="month" selected={@chart_time_range == :month}>30 Days</option>
              </select>
            </form>
          </div>

          <.live_component
            module={Web.Components.SensorChart}
            id="sensor-chart"
            data={@chart_data}
            metric={@chart_metric}
            time_range={@chart_time_range}
            fan_events={@chart_fan_events}
          />
        </div>
      </div>
    </div>

    <div>
      <h2>Fan Control</h2>
      <button phx-click="set_relay" phx-value-relay="0" class="off">
        Off
      </button>
      <button
        phx-click="set_relay"
        phx-value-relay="1"
        class={if @fan_state.current_relay == 1, do: "active", else: "speed"}
        disabled={@fan_state.current_relay == 1}
      >
        Speed 1
      </button>
      <button
        phx-click="set_relay"
        phx-value-relay="2"
        class={if @fan_state.current_relay == 2, do: "active", else: "speed"}
        disabled={@fan_state.current_relay == 2}
      >
        Speed 2
      </button>
      <button
        phx-click="set_relay"
        phx-value-relay="3"
        class={if @fan_state.current_relay == 3, do: "active", else: "speed"}
        disabled={@fan_state.current_relay == 3}
      >
        Speed 3
      </button>
    </div>

    <div class="events">
      <h2>Recent Events</h2>
      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Speed</th>
            <th>Action</th>
            <th>Source</th>
          </tr>
        </thead>
        <tbody>
          <%= for event <- @events do %>
            <tr>
              <td><%= format_datetime(event.inserted_at) %></td>
              <td><%= relay_to_speed_text(event.relay_number) %></td>
              <td><%= event.action %></td>
              <td><%= event.source %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp get_fan_state do
    try do
      FanController.get_state()
    rescue
      _ -> %{current_relay: nil}
    end
  end

  defp get_current_reading do
    try do
      AirSensor.read_current()
    rescue
      _ -> nil
    end
  end

  defp load_recent_events do
    Repo.all(
      from(e in Event,
        order_by: [desc: e.inserted_at],
        limit: 20
      )
    )
  end

  defp fan_speed_text(%{current_relay: nil}), do: "Off"

  defp fan_speed_text(%{current_relay: relay}) do
    # Relay numbers match speed numbers: relay 1 = speed 1 (slowest), relay 3 = speed 3 (fastest)
    "Speed #{relay}"
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end

  defp format_time_until(next_cycle_time) do
    format_datetime(next_cycle_time)
  end

  defp relay_to_speed_text(relay_number) do
    # Relay numbers match speed numbers: relay 1 = speed 1 (slowest), relay 3 = speed 3 (fastest)
    case relay_number do
      1 -> "1"
      2 -> "2"
      3 -> "3"
      _ -> "Off"
    end
  end

  defp host_mode? do
    Application.get_env(:boxfan, :gpio) == Host.GPIO
  end

  defp schedule_host_refresh do
    Process.send_after(self(), :refresh_host_state, 1000)
  end

  defp schedule_next_cycle_refresh(next_cycle_time) do
    now = DateTime.utc_now()
    delay_ms = DateTime.diff(next_cycle_time, now, :millisecond)

    if delay_ms > 0 do
      Process.send_after(self(), :refresh_next_cycle, delay_ms)
    end
  end

  defp get_host_gpio_state do
    Application.get_env(:boxfan, :host_gpio_pins, %{})
  end

  defp load_chart_data(time_range) do
    SensorReading.for_time_range(time_range)
  end

  defp load_fan_events(time_range) when time_range in [:hour, :day] do
    cutoff_time = calculate_event_cutoff_time(time_range)

    Repo.all(
      from(e in Event,
        where: e.inserted_at >= ^cutoff_time,
        order_by: [asc: e.inserted_at]
      )
    )
  end

  defp load_fan_events(_time_range), do: []

  defp calculate_event_cutoff_time(:hour) do
    DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
  end

  defp calculate_event_cutoff_time(:day) do
    DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
  end

  defp render_host_gpio_state(pins) do
    pin_info =
      pins
      |> Enum.map(fn {_ref, pin_state} ->
        status = if pin_state.value == 0, do: "ON (LOW)", else: "OFF (HIGH)"
        "Pin #{pin_state.pin}: #{status}"
      end)
      |> Enum.sort()
      |> Enum.join(" | ")

    if pin_info == "" do
      Phoenix.HTML.raw("<p><strong>GPIO State:</strong> Initializing...</p>")
    else
      Phoenix.HTML.raw("<p><strong>GPIO State:</strong> #{pin_info}</p>")
    end
  end
end
