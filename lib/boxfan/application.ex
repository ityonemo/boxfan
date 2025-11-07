defmodule Boxfan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @target Mix.target()
  @tailscale_auth_key Application.compile_env(:boxfan, :tailscale_auth_key)
  @bme680 Application.compile_env(:boxfan, :bme680, Bme680)

  @impl true
  def start(_type, _args) do
    # Run migrations before starting children (except in test env)
    unless Application.get_env(:boxfan, :env) == :test do
      Boxfan.Release.migrate()
    end

    children =
      [
        # Children for all targets
        Data.Repo,
        {Phoenix.PubSub, name: Boxfan.PubSub},
        Web.Endpoint
      ] ++ target_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  defp target_children() do
    # Don't start hardware GenServers in test environment
    # (tests start them manually when needed)
    case {Application.get_env(:boxfan, :env), @target} do
      {:test, _} ->
        []

      {_, :host} ->
        base_children()

      _ ->
        [bme680_child()] ++ base_children() ++ [{Boxfan.Tailscale, tailscale_config()}]
    end
  end

  defp base_children do
    [
      # Hardware GenServers for all targets (including host with mocks)
      {Boxfan.FanController, relay_pins: fan_controller_config()},
      {Boxfan.AirSensor, air_sensor_config()},
      {Boxfan.Scheduler, scheduler_config()}
    ]
  end

  defp bme680_child do
    %{
      id: Bme680,
      start: {Bme680, :start_link, [bme680_config(), [name: Boxfan.Bme680]]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  defp fan_controller_config do
    Application.get_env(:boxfan, Boxfan.FanController, [])
    |> Keyword.get(:relay_pins, %{})
  end

  defp bme680_config do
    config = Application.get_env(:boxfan, Boxfan.Bme680Sensor, [])

    # Extract device number from bus string (e.g., "i2c-1" -> 1)
    bus = Keyword.get(config, :bus, "i2c-1")

    device_number =
      case String.split(bus, "-") do
        [_prefix, num] -> String.to_integer(num)
        # default to 1
        _ -> 1
      end

    [
      i2c_device_number: device_number,
      i2c_address: Keyword.get(config, :address, 0x77),
      temperature_offset: Keyword.get(config, :temperature_offset, 0)
    ]
  end

  defp air_sensor_config do
    config = Application.get_env(:boxfan, Boxfan.AirSensor, [])

    [
      sample_interval: Keyword.get(config, :sample_interval, :timer.seconds(60)),
      data_retention_days: Keyword.get(config, :data_retention_days, 30)
    ]
  end

  defp scheduler_config do
    config = Application.get_env(:boxfan, Boxfan.Scheduler, [])

    [
      ventilation_interval: Keyword.get(config, :ventilation_interval, :timer.minutes(60)),
      ventilation_duration: Keyword.get(config, :ventilation_duration, :timer.minutes(5))
    ]
  end

  defp tailscale_config do
    # Use compile-time captured auth key
    [auth_key: @tailscale_auth_key]
  end
end
