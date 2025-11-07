# Start the Repo for tests
{:ok, _} = Application.ensure_all_started(:boxfan)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Data.Repo, :manual)

# For in-memory database, migrations are run in each test via DataCase
