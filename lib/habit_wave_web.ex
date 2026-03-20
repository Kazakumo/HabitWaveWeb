defmodule HabitWaveWeb do
  @moduledoc """
  HabitWaveWeb keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @spec controller() :: {:__block__, [], [...]}
  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: HabitWaveWebWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HabitWaveWebWeb.Endpoint,
        router: HabitWaveWebWeb.Router,
        statics: HabitWaveWebWeb.static_paths()
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: HabitWaveWebWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import HabitWaveWebWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias HabitWaveWebWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(internal_verified_routes())
    end
  end

  defp internal_verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HabitWaveWebWeb.Endpoint,
        router: HabitWaveWebWeb.Router,
        statics: HabitWaveWebWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate live_view definition.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
