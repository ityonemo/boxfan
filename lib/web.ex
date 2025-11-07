defmodule Web do
  @moduledoc """
  The Web context for Phoenix components.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  defmodule VerifiedRoutes do
    @moduledoc """
    Verified routes for compile-time route verification.
    """
    defmacro __using__(_opts) do
      quote do
        use Phoenix.VerifiedRoutes,
          endpoint: Web.Endpoint,
          router: Web.Router,
          statics: Web.static_paths()
      end
    end
  end
end
