defmodule Boxfan.Tailscale do
  @moduledoc """
  Manages Tailscale VPN connection for remote access.

  Starts tailscaled daemon using MuonTrap.
  """
  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  @doc """
  Starts the tailscaled daemon.

  This directly delegates to MuonTrap.Daemon to supervise the tailscaled process.
  After the daemon starts, authenticate with `connect/1`.
  """
  def start_link(opts) do
    Logger.info("Starting tailscaled daemon...")

    # Start tailscaled daemon - MuonTrap will supervise it
    result =
      MuonTrap.Daemon.start_link(
        "tailscaled",
        [
          "--tun=userspace-networking",
          "--state=/root/tailscale.state"
        ],
        stderr_to_stdout: true
      )

    # Schedule connection in background if auth key provided
    if auth_key = Keyword.get(opts, :auth_key) do
      Task.start(fn ->
        # Give daemon time to start
        Process.sleep(5000)
        connect(auth_key)
      end)
    end

    result
  end

  @doc """
  Connects to Tailscale network using auth key.
  """
  def connect(auth_key) do
    Logger.info("Connecting to Tailscale network...")

    case MuonTrap.cmd("tailscale", [
           "up",
           "--authkey=#{auth_key}",
           "--accept-routes",
           "--hostname=boxfan"
         ]) do
      {output, 0} ->
        Logger.info("Tailscale connected: #{inspect(output)}")
        :ok

      {output, _exit_code} ->
        output_str = to_string(output)

        if String.contains?(output_str, "already logged in") do
          Logger.info("Tailscale already connected")
          :ok
        else
          Logger.error("Failed to connect Tailscale: #{output_str}")
          {:error, output_str}
        end
    end
  end
end
