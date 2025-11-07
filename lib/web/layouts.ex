defmodule Web.Layouts do
  @moduledoc """
  Layout components for the web interface.
  """

  use Phoenix.Component

  # Import convenience functions from controllers
  import Phoenix.Controller,
    only: [get_csrf_token: 0, view_module: 1, view_template: 1]

  # Routes generation with the ~p sigil
  use Web.VerifiedRoutes

  embed_templates("layouts/*")
end
