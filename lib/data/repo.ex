defmodule Data.Repo do
  use Ecto.Repo,
    otp_app: :boxfan,
    adapter: Ecto.Adapters.SQLite3
end
