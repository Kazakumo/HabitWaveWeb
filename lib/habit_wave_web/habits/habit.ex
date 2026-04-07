defmodule HabitWaveWeb.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          user_id: integer(),
          title: String.t(),
          type: integer(),
          is_active: boolean(),
          frequency_type: String.t(),
          interval_days: integer(),
          start_date: Date.t(),
          user: HabitWaveWeb.Accounts.User.t() | Ecto.Association.NotLoaded.t(),
          settings: HabitWaveWeb.Habits.HabitSettings.t() | Ecto.Association.NotLoaded.t(),
          habit_logs: [HabitWaveWeb.Habits.HabitLog.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habits" do
    field :title, :string
    field :type, :integer, default: 0
    field :is_active, :boolean, default: true
    field :frequency_type, :string, default: "daily"
    field :interval_days, :integer, default: 1
    field :start_date, :date

    belongs_to :user, HabitWaveWeb.Accounts.User
    has_one :settings, HabitWaveWeb.Habits.HabitSettings
    has_many :habit_logs, HabitWaveWeb.Habits.HabitLog

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
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [
      :title,
      :type,
      :is_active,
      :frequency_type,
      :interval_days,
      :start_date,
      :user_id
    ])
    |> validate_required([:title, :interval_days, :start_date, :user_id])
    |> validate_number(:interval_days, greater_than: 0)
    |> validate_inclusion(:type, [0, 1])
    |> validate_inclusion(:frequency_type, ["daily", "interval"])
  end
end
