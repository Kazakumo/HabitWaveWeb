defmodule HabitWaveWeb.Repo.Migrations.CreateHabitLogs do
  use Ecto.Migration

  def change do
    create table(:habit_logs) do
      add :habit_id, references(:habits, on_delete: :delete_all), null: false
      add :target_date, :date, null: false
      add :recorded_at, :utc_datetime, null: false
      add :value, :float, null: false, default: 1.0

      timestamps(type: :utc_datetime)
    end

    create index(:habit_logs, [:habit_id])
    create index(:habit_logs, [:target_date])
    create unique_index(:habit_logs, [:habit_id, :target_date])
  end
end
