defmodule HabitWaveWeb.Repo.Migrations.CreateHabitSettings do
  use Ecto.Migration

  def change do
    create table(:habit_settings) do
      add :habit_id, references(:habits, on_delete: :delete_all), null: false
      add :color_hex, :string, null: false, default: "#6200EE"
      add :reminder_time, :string
      add :total_goal_value, :float
      add :unit, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:habit_settings, [:habit_id])
  end
end
