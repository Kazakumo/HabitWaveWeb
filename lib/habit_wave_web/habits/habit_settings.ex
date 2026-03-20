defmodule HabitWaveWeb.Habits.HabitSettings do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          habit_id: integer(),
          color_hex: String.t(),
          reminder_time: String.t() | nil,
          total_goal_value: float() | nil,
          unit: String.t() | nil,
          habit: HabitWaveWeb.Habits.Habit.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habit_settings" do
    field :color_hex, :string, default: "#6200EE"
    field :reminder_time, :string
    field :total_goal_value, :float
    field :unit, :string

    belongs_to :habit, HabitWaveWeb.Habits.Habit

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:color_hex, :reminder_time, :total_goal_value, :unit])
    |> validate_format(:color_hex, ~r/^#[0-9A-Fa-f]{6}$/)
  end
end
