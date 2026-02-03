defmodule HabitWaveWeb.Repo do
  use Ecto.Repo,
    otp_app: :habit_wave_web,
    adapter: Ecto.Adapters.Postgres
end
