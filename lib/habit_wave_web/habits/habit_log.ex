defmodule HabitWaveWeb.Habits.HabitLog do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          habit_id: integer(),
          target_date: Date.t(),
          recorded_at: DateTime.t(),
          value: float(),
          habit: HabitWaveWeb.Habits.Habit.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habit_logs" do
    field :target_date, :date
    field :recorded_at, :utc_datetime
    field :value, :float, default: 1.0

    belongs_to :habit, HabitWaveWeb.Habits.Habit

    timestamps(type: :utc_datetime)
  end

  def changeset(habit_log, attrs) do
    habit_log
    |> cast(attrs, [:target_date, :recorded_at, :value, :habit_id])
    |> validate_required([:target_date, :recorded_at, :habit_id])
    |> validate_number(:value, greater_than_or_equal_to: 0.0)
    |> unique_constraint([:habit_id, :target_date])
  end
end
