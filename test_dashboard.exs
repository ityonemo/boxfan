# Test script to interact with dashboard using headless browser
# Run with: mix run test_dashboard.exs

# Start ChromeDriver if not running
System.cmd("pkill", ["-f", "chromedriver"], stderr_to_stdout: true)
Process.sleep(500)

case System.cmd("which", ["chromedriver"]) do
  {_, 0} ->
    IO.puts("Starting ChromeDriver...")
    spawn(fn -> System.cmd("chromedriver", ["--port=9515"], into: IO.stream(:stdio, :line)) end)
    Process.sleep(2000)
  _ ->
    IO.puts("ChromeDriver not found. Trying geckodriver (Firefox)...")
    case System.cmd("which", ["geckodriver"]) do
      {_, 0} ->
        spawn(fn -> System.cmd("geckodriver", [], into: IO.stream(:stdio, :line)) end)
        Process.sleep(2000)
      _ ->
        IO.puts("ERROR: Neither chromedriver nor geckodriver found!")
        IO.puts("Please install one:")
        IO.puts("  Ubuntu/Debian: sudo apt-get install chromium-chromedriver")
        IO.puts("  or: sudo apt-get install firefox-geckodriver")
        System.halt(1)
    end
end

# Configure Wallaby
Application.put_env(:wallaby, :base_url, "http://localhost:4000")
Application.put_env(:wallaby, :driver, Wallaby.Chrome)
Application.put_env(:wallaby, :screenshot_on_failure, true)

{:ok, _} = Application.ensure_all_started(:wallaby)

alias Wallaby.Browser
alias Wallaby.Query

IO.puts("\n=== Starting Browser Session ===")
{:ok, session} = Wallaby.start_session(
  capabilities: %{
    chromeOptions: %{
      args: ["--no-sandbox", "--headless", "--disable-gpu", "--disable-dev-shm-usage"]
    }
  }
)

try do
  session
  |> Browser.visit("/")
  |> Browser.take_screenshot(name: "01_initial_load")

  IO.puts("✓ Loaded dashboard")

  # Check initial state
  fan_speed = Browser.text(session, Query.css(".status p"))
  IO.puts("Current: #{fan_speed}")

  # Click Speed 1 button
  IO.puts("\n=== Clicking Speed 1 Button ===")
  session = Browser.click(session, Query.button("Speed 1"))
  Process.sleep(1000)
  session |> Browser.take_screenshot(name: "02_speed_1")

  fan_speed = Browser.text(session, Query.css(".status p"))
  IO.puts("After Speed 1: #{fan_speed}")

  # Check button states
  speed1_elem = Browser.find(session, Query.button("Speed 1"))
  speed1_class = Browser.attr(speed1_elem, "class")
  IO.puts("Speed 1 button class: #{inspect(speed1_class)}")

  # Click Speed 3 button
  IO.puts("\n=== Clicking Speed 3 Button ===")
  session = Browser.click(session, Query.button("Speed 3"))
  Process.sleep(1000)
  session |> Browser.take_screenshot(name: "03_speed_3")

  fan_speed = Browser.text(session, Query.css(".status p"))
  IO.puts("After Speed 3: #{fan_speed}")

  # Click Off button
  IO.puts("\n=== Clicking Off Button ===")
  session = Browser.click(session, Query.button("Off"))
  Process.sleep(1000)
  session |> Browser.take_screenshot(name: "04_off")

  fan_speed = Browser.text(session, Query.css(".status p"))
  IO.puts("After Off: #{fan_speed}")

  # Check GPIO state display
  if Browser.has?(session, Query.css(".host-debug")) do
    gpio_state = Browser.text(session, Query.css(".host-debug p"))
    IO.puts("\nGPIO State: #{gpio_state}")
  end

  IO.puts("\n✓ All tests completed!")
  IO.puts("Screenshots saved in: screenshots/")

after
  Wallaby.end_session(session)
  IO.puts("\n=== Browser Session Ended ===")
end
