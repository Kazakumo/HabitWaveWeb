defmodule HabitWaveWebWeb.PageController do
  use HabitWaveWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
