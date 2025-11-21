defmodule Web.Components.SensorChart do
  @moduledoc """
  LiveComponent for rendering sensor data charts as SVG.
  """

  use Phoenix.LiveComponent

  # Chart dimensions constants
  @width 600
  @height 250
  @margin_left 60
  @margin_bottom 50
  @margin_top 25
  @margin_right 25

  def render(assigns) do
    assigns = prepare_chart_data(assigns)

    ~H"""
    <div class="sensor-chart">
      <p :if={@data == []} style="color: #666;">No data available for this time range</p>
      <div :if={@data != []} class="chart-container" style="width: 100%;">
        <svg viewBox={"0 0 #{@chart.width} #{@chart.height}"} preserveAspectRatio="xMidYMid meet" style="width: 100%; height: auto; border: 1px solid #ccc; background: white;">
          <!-- Y-axis -->
          <line
            x1={@chart.margin_left}
            y1={@chart.margin_top}
            x2={@chart.margin_left}
            y2={@chart.height - @chart.margin_bottom}
            stroke="black"
            stroke-width="1"
          />
          <!-- X-axis -->
          <line
            x1={@chart.margin_left}
            y1={@chart.height - @chart.margin_bottom}
            x2={@chart.width - @chart.margin_right}
            y2={@chart.height - @chart.margin_bottom}
            stroke="black"
            stroke-width="1"
          />
          <!-- Y-axis label -->
          <text
            x="30"
            y={@chart.height / 2}
            font-size="12"
            text-anchor="middle"
            transform={"rotate(-90, 30, #{@chart.height / 2})"}
          >
            <%= @chart.y_label %> (<%= @chart.y_unit %>)
          </text>
          <!-- Y-axis tick labels -->
          <text
            x={@chart.margin_left - 5}
            y={@chart.margin_top + 5}
            font-size="10"
            text-anchor="end"
          >
            <%= @chart.y_max_label %>
          </text>
          <text
            x={@chart.margin_left - 5}
            y={@chart.height - @chart.margin_bottom + 5}
            font-size="10"
            text-anchor="end"
          >
            <%= @chart.y_min_label %>
          </text>
          <!-- X-axis tick marks and labels -->
          <g :for={tick <- @chart.x_ticks}>
            <line
              x1={tick.x}
              y1={tick.y}
              x2={tick.x}
              y2={tick.y + 5}
              stroke="black"
              stroke-width="1"
            />
            <text x={tick.x} y={tick.y + 18} font-size="9" text-anchor="middle">
              <%= tick.label %>
            </text>
          </g>
          <!-- X-axis label -->
          <text x={@chart.width / 2} y={@chart.height - 10} font-size="12" text-anchor="middle">
            Time (<%= @chart.x_label %>)
          </text>
          <!-- Fan on stripes (amber) -->
          <g :for={stripe <- @chart.fan_stripes}>
            <defs>
              <linearGradient id={"gradient-#{stripe.id}"} x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:#CC8800;stop-opacity:1" />
                <stop offset="5%" style="stop-color:#FFCC66;stop-opacity:0.6" />
                <stop offset="95%" style="stop-color:#FFCC66;stop-opacity:0.6" />
                <stop offset="100%" style="stop-color:#CC8800;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect
              x={stripe.x}
              y={stripe.y}
              width={stripe.width}
              height={stripe.height}
              fill={"url(#gradient-#{stripe.id})"}
            />
          </g>
          <!-- Data line -->
          <polyline points={@chart.points} fill="none" stroke="#007bff" stroke-width="2" />
          <!-- Legend (only if fan stripes exist) -->
          <g :if={@chart.fan_stripes != []}>
            <rect
              x="15"
              y={@chart.height - @chart.margin_bottom + 28}
              width="20"
              height="12"
              fill="#FFCC66"
              stroke="#CC8800"
              stroke-width="1"
              opacity="0.7"
            />
            <text
              x="40"
              y={@chart.height - @chart.margin_bottom + 38}
              font-size="10"
              fill="#333"
            >
              Fan Cycle
            </text>
          </g>
        </svg>
      </div>
    </div>
    """
  end

  defp prepare_chart_data(%{data: []} = assigns) do
    assign(assigns, :chart, %{fan_stripes: []})
  end

  defp prepare_chart_data(%{data: data, metric: metric, time_range: time_range} = assigns) do
    # Extract values for the selected metric
    values = Enum.map(data, &Map.get(&1, metric))

    # Calculate min and max for scaling
    {data_min, data_max} = Enum.min_max(values)

    # Round to nice numbers based on metric
    chart_min = round_axis_min(data_min, metric)
    chart_max = round_axis_max(data_max, metric)

    plot_width = @width - @margin_left - @margin_right
    plot_height = @height - @margin_top - @margin_bottom

    # Calculate the full time range
    now = DateTime.utc_now()
    time_range_start = calculate_time_range_start(now, time_range)
    time_range_end = now
    time_span_ms = DateTime.diff(time_range_end, time_range_start, :millisecond)

    # Calculate points for the polyline using absolute time positioning
    points =
      data
      |> Enum.map(fn reading ->
        val = Map.get(reading, metric)
        timestamp = reading.inserted_at

        # Calculate X position based on timestamp within the time range
        time_offset_ms = DateTime.diff(timestamp, time_range_start, :millisecond)
        x = @margin_left + time_offset_ms / time_span_ms * plot_width

        # Invert y because SVG y-axis goes down
        y = @margin_top + plot_height - (val - chart_min) / (chart_max - chart_min) * plot_height
        "#{x},#{y}"
      end)
      |> Enum.join(" ")

    # Get metric label and unit
    {y_label, y_unit} = metric_label_and_unit(metric)

    # X-axis tick marks at meaningful time boundaries
    x_ticks =
      build_time_boundary_ticks(
        time_range_start,
        time_range_end,
        time_range,
        @margin_left,
        plot_width,
        @height - @margin_bottom
      )

    # Build fan on stripes
    fan_stripes =
      build_fan_stripes(
        Map.get(assigns, :fan_events, []),
        time_range_start,
        time_range_end,
        time_span_ms,
        @margin_left,
        @margin_top,
        plot_width,
        plot_height
      )

    chart_data = %{
      width: @width,
      height: @height,
      margin_left: @margin_left,
      margin_bottom: @margin_bottom,
      margin_top: @margin_top,
      margin_right: @margin_right,
      points: points,
      y_label: y_label,
      y_unit: y_unit,
      y_max_label: format_axis_tick(chart_max, metric),
      y_min_label: format_axis_tick(chart_min, metric),
      x_label: time_range_label(time_range),
      x_ticks: x_ticks,
      fan_stripes: fan_stripes
    }

    assign(assigns, :chart, chart_data)
  end

  defp calculate_time_range_start(now, :hour) do
    DateTime.add(now, -1, :hour) |> DateTime.truncate(:second)
  end

  defp calculate_time_range_start(now, :day) do
    DateTime.add(now, -1, :day) |> DateTime.truncate(:second)
  end

  defp calculate_time_range_start(now, :week) do
    DateTime.add(now, -7, :day) |> DateTime.truncate(:second)
  end

  defp calculate_time_range_start(now, :month) do
    DateTime.add(now, -30, :day) |> DateTime.truncate(:second)
  end

  defp metric_label_and_unit(:temperature), do: {"Temperature", "°C"}
  defp metric_label_and_unit(:humidity), do: {"Humidity", "%"}
  defp metric_label_and_unit(:pressure), do: {"Pressure", " hPa"}
  defp metric_label_and_unit(:gas_resistance), do: {"Gas Resistance", " Ω"}

  defp time_range_label(:hour), do: "Last Hour"
  defp time_range_label(:day), do: "Last 24 Hours"
  defp time_range_label(:week), do: "Last 7 Days"
  defp time_range_label(:month), do: "Last 30 Days"

  # Format axis tick labels
  defp format_axis_tick(val, :temperature), do: trunc(val)
  defp format_axis_tick(val, :humidity), do: trunc(val)
  defp format_axis_tick(val, :gas_resistance), do: trunc(val)
  defp format_axis_tick(val, :pressure), do: Float.round(val, 1)

  # Round axis min down to nice numbers
  defp round_axis_min(val, :temperature) do
    # Round down to nearest 5°C
    floor(val / 5) * 5
  end

  defp round_axis_min(val, :humidity) do
    # Round down to nearest 10%
    floor(val / 10) * 10
  end

  defp round_axis_min(val, :pressure) do
    # Keep original logic for pressure
    val
  end

  defp round_axis_min(val, :gas_resistance) do
    # Round down to nearest 5000 Ω
    floor(val / 5000) * 5000
  end

  # Round axis max up to nice numbers
  defp round_axis_max(val, :temperature) do
    # Round up to nearest 5°C
    ceil(val / 5) * 5
  end

  defp round_axis_max(val, :humidity) do
    # Round up to nearest 10%
    ceil(val / 10) * 10
  end

  defp round_axis_max(val, :pressure) do
    # Keep original logic for pressure
    val
  end

  defp round_axis_max(val, :gas_resistance) do
    # Round up to nearest 5000 Ω
    ceil(val / 5000) * 5000
  end

  defp build_time_boundary_ticks(
         time_range_start,
         time_range_end,
         time_range,
         margin_left,
         plot_width,
         y_pos
       ) do
    time_span_ms = DateTime.diff(time_range_end, time_range_start, :millisecond)

    # Generate tick times based on time range
    tick_times = generate_tick_times(time_range_start, time_range_end, time_range)

    # Convert to tick data with positions
    tick_times
    |> Enum.map(fn tick_time ->
      time_offset_ms = DateTime.diff(tick_time, time_range_start, :millisecond)
      x = margin_left + time_offset_ms / time_span_ms * plot_width
      label = format_x_tick(tick_time, time_range)

      %{x: x, y: y_pos, label: label}
    end)
  end

  defp generate_tick_times(time_range_start, time_range_end, :hour) do
    # 10-minute intervals on the 10-minute marks
    start_time =
      time_range_start
      |> DateTime.truncate(:second)
      |> Map.put(:second, 0)
      |> round_up_to_minutes(10)

    generate_ticks_by_interval(start_time, time_range_end, 10, :minute)
  end

  defp generate_tick_times(time_range_start, time_range_end, :day) do
    # Every 4 hours
    start_time =
      time_range_start
      |> DateTime.truncate(:second)
      |> Map.put(:second, 0)
      |> Map.put(:minute, 0)
      |> round_up_to_hours(4)

    generate_ticks_by_interval(start_time, time_range_end, 4, :hour)
  end

  defp generate_tick_times(time_range_start, time_range_end, :week) do
    # Every day at midnight
    start_time =
      time_range_start
      |> DateTime.to_date()
      |> Date.add(1)
      |> DateTime.new!(~T[00:00:00])

    generate_ticks_by_interval(start_time, time_range_end, 1, :day)
  end

  defp generate_tick_times(time_range_start, time_range_end, :month) do
    # Every 3 days at midnight
    start_time =
      time_range_start
      |> DateTime.to_date()
      |> Date.add(1)
      |> DateTime.new!(~T[00:00:00])

    generate_ticks_by_interval(start_time, time_range_end, 3, :day)
  end

  defp round_up_to_minutes(datetime, interval) do
    current_minute = datetime.minute
    next_boundary = ceil(current_minute / interval) * interval

    if next_boundary >= 60 do
      datetime
      |> Map.put(:minute, 0)
      |> DateTime.add(1, :hour)
    else
      Map.put(datetime, :minute, next_boundary)
    end
  end

  defp round_up_to_hours(datetime, interval) do
    current_hour = datetime.hour
    next_boundary = ceil(current_hour / interval) * interval

    if next_boundary >= 24 do
      datetime
      |> Map.put(:hour, 0)
      |> DateTime.add(1, :day)
    else
      Map.put(datetime, :hour, next_boundary)
    end
  end

  defp generate_ticks_by_interval(start_time, end_time, interval, unit) do
    Stream.iterate(start_time, fn time ->
      DateTime.add(time, interval, unit)
    end)
    |> Enum.take_while(fn time ->
      DateTime.compare(time, end_time) != :gt
    end)
  end

  defp format_x_tick(datetime, :hour) do
    Calendar.strftime(datetime, "%H:%M")
  end

  defp format_x_tick(datetime, :day) do
    Calendar.strftime(datetime, "%H:%M")
  end

  defp format_x_tick(datetime, :week) do
    Calendar.strftime(datetime, "%b %d")
  end

  defp format_x_tick(datetime, :month) do
    Calendar.strftime(datetime, "%b %d")
  end

  defp build_fan_stripes(
         [],
         _time_range_start,
         _time_range_end,
         _time_span_ms,
         _margin_left,
         _margin_top,
         _plot_width,
         _plot_height
       ) do
    []
  end

  defp build_fan_stripes(
         events,
         time_range_start,
         time_range_end,
         time_span_ms,
         margin_left,
         margin_top,
         plot_width,
         plot_height
       ) do
    # Convert events to a list of on/off periods
    events
    |> pair_fan_events(time_range_start, time_range_end)
    |> Enum.with_index()
    |> Enum.map(fn {{start_time, end_time}, idx} ->
      # Calculate X positions based on timestamps
      start_offset_ms = DateTime.diff(start_time, time_range_start, :millisecond)
      end_offset_ms = DateTime.diff(end_time, time_range_start, :millisecond)

      x1 = margin_left + start_offset_ms / time_span_ms * plot_width
      x2 = margin_left + end_offset_ms / time_span_ms * plot_width

      %{
        id: idx,
        x: x1,
        y: margin_top,
        # Ensure minimum width of 1px
        width: max(x2 - x1, 1),
        height: plot_height
      }
    end)
  end

  defp pair_fan_events(events, time_range_start, time_range_end) do
    # Group events by relay and pair on/off events
    events
    |> Enum.group_by(& &1.relay_number)
    |> Enum.flat_map(fn {_relay, relay_events} ->
      pair_on_off_events(relay_events, time_range_start, time_range_end)
    end)
  end

  defp pair_on_off_events(events, _time_range_start, time_range_end) do
    events
    |> Enum.reduce({[], nil}, fn event, {periods, current_on_time} ->
      case {event.action, current_on_time} do
        {"on", nil} ->
          # Fan turned on
          {periods, event.inserted_at}

        {"off", on_time} when not is_nil(on_time) ->
          # Fan turned off - create a period
          {[{on_time, event.inserted_at} | periods], nil}

        _ ->
          # Invalid sequence or duplicate action - ignore
          {periods, current_on_time}
      end
    end)
    |> then(fn {periods, current_on_time} ->
      # If fan is still on at the end, create a period extending to now
      if current_on_time do
        [{current_on_time, time_range_end} | periods]
      else
        periods
      end
    end)
    |> Enum.reverse()
  end
end
