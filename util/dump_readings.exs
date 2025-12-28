# Dump sensor readings from boxfan device via Erlang distribution
#
# Usage:
#   elixir --name dump@$(hostname).local --cookie boxfan_cookie util/dump_readings.exs
#
# Options:
#   --output FILE    Output file (default: readings_TIMESTAMP.csv)
#   --format FORMAT  Output format: csv or json (default: csv)
#   --node NODE      Target node (default: boxfan@boxfan.local)

Mix.install([:jason])

defmodule DumpReadings do
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [output: :string, format: :string, node: :string]
      )

    node = String.to_atom(opts[:node] || "boxfan@boxfan.local")
    format = opts[:format] || "csv"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic) |> String.slice(0, 15)
    output = opts[:output] || "readings_#{timestamp}.#{format}"

    IO.puts("Connecting to #{node}...")

    case Node.connect(node) do
      true ->
        IO.puts("Connected!")
        fetch_and_dump(node, output, format)

      false ->
        IO.puts("Failed to connect to #{node}")
        IO.puts("Make sure:")
        IO.puts("  1. boxfan is running with distribution enabled")
        IO.puts("  2. You're using the correct cookie (boxfan_cookie)")
        IO.puts("  3. You started this script with --name and --cookie flags")
        System.halt(1)
    end
  end

  defp fetch_and_dump(node, output, format) do
    IO.puts("Fetching readings...")

    readings =
      :rpc.call(node, Data.Repo, :all, [Data.SensorReading])
      |> Enum.sort_by(& &1.inserted_at, DateTime)

    IO.puts("Got #{length(readings)} readings")

    content =
      case format do
        "csv" -> to_csv(readings)
        "json" -> to_json(readings)
        _ -> raise "Unknown format: #{format}"
      end

    File.write!(output, content)
    IO.puts("Wrote to #{output}")
  end

  defp to_csv(readings) do
    header = "id,temperature,humidity,pressure,gas_resistance,inserted_at\n"

    rows =
      readings
      |> Enum.map(fn r ->
        "#{r.id},#{r.temperature},#{r.humidity},#{r.pressure},#{r.gas_resistance},#{DateTime.to_iso8601(r.inserted_at)}"
      end)
      |> Enum.join("\n")

    header <> rows <> "\n"
  end

  defp to_json(readings) do
    readings
    |> Enum.map(fn r ->
      %{
        id: r.id,
        temperature: r.temperature,
        humidity: r.humidity,
        pressure: r.pressure,
        gas_resistance: r.gas_resistance,
        inserted_at: DateTime.to_iso8601(r.inserted_at)
      }
    end)
    |> Jason.encode!(pretty: true)
  end
end

DumpReadings.run(System.argv())
