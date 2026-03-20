defmodule HabitWaveWeb.Repo.Migrations.CreateHabits do
  use Ecto.Migration

  def change do
    create table(:habits) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :type, :integer, null: false, default: 0
      add :is_active, :boolean, null: false, default: true
      add :frequency_type, :string, null: false, default: "daily"
      add :interval_days, :integer, null: false, default: 1
      add :start_date, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:habits, [:user_id])
    create index(:habits, [:is_active])
  end
end
