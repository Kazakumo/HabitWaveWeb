defmodule HabitWaveWeb.Habits do
  @moduledoc """
  Context for managing habits, settings, and logs.
  """

  import Ecto.Query
  alias HabitWaveWeb.Repo
  alias HabitWaveWeb.Habits.{Habit, HabitSettings, HabitLog, Logic}

  ## Habit CRUD

  @spec list_habits(integer()) :: [Habit.t()]
  def list_habits(user_id) do
    Habit
    |> where([h], h.user_id == ^user_id)
    |> preload([:settings, :habit_logs])
    |> order_by([h], desc: h.inserted_at)
    |> Repo.all()
  end

  @spec get_habit!(integer(), integer()) :: Habit.t()
  def get_habit!(id, user_id) do
    Habit
    |> where([h], h.id == ^id and h.user_id == ^user_id)
    |> preload([:settings, :habit_logs])
    |> Repo.one!()
  end

  @spec create_habit(map(), integer()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def create_habit(attrs, user_id) do
    habit_attrs = Map.put(attrs, "user_id", user_id)

    %Habit{}
    |> Habit.changeset(habit_attrs)
    |> Ecto.Changeset.put_assoc(:settings, %HabitSettings{})
    |> Repo.insert()
  end

  @spec update_habit(Habit.t(), map()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def update_habit(%Habit{} = habit, attrs) do
    habit
    |> Habit.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_habit(Habit.t()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def delete_habit(%Habit{} = habit), do: Repo.delete(habit)

  @spec change_habit(Habit.t(), map()) :: Ecto.Changeset.t()
  def change_habit(%Habit{} = habit, attrs \\ %{}) do
    Habit.changeset(habit, attrs)
  end

  ## Habit Log Operations

  @spec log_habit(Habit.t(), float(), Date.t()) ::
          {:ok, HabitLog.t()} | {:error, Ecto.Changeset.t() | :no_valid_target | :already_logged}
  def log_habit(%Habit{} = habit, value \\ 1.0, reference_date \\ Date.utc_today()) do
    case Logic.determine_target_date(habit, reference_date) do
      {:ok, target_date} ->
        existing = Repo.get_by(HabitLog, habit_id: habit.id, target_date: target_date)

        if existing do
          {:error, :already_logged}
        else
          %HabitLog{}
          |> HabitLog.changeset(%{
            habit_id: habit.id,
            target_date: target_date,
            recorded_at: DateTime.utc_now(),
            value: value
          })
          |> Repo.insert()
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec toggle_habit_log(Habit.t(), Date.t()) ::
          {:ok, :created | :deleted} | {:error, Ecto.Changeset.t() | atom()}
  def toggle_habit_log(%Habit{} = habit, reference_date \\ Date.utc_today()) do
    case Logic.determine_target_date(habit, reference_date) do
      {:ok, target_date} ->
        existing = Repo.get_by(HabitLog, habit_id: habit.id, target_date: target_date)

        if existing do
          Repo.delete(existing)
          {:ok, :deleted}
        else
          case log_habit(habit, 1.0, reference_date) do
            {:ok, _log} -> {:ok, :created}
            error -> error
          end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec get_habit_with_streak(integer(), integer(), Date.t()) ::
          {:ok, %{habit: Habit.t(), streak: Logic.streak_result()}} | {:error, :not_found}
  def get_habit_with_streak(habit_id, user_id, reference_date \\ Date.utc_today()) do
    case Repo.get_by(Habit, id: habit_id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      habit ->
        habit = Repo.preload(habit, :habit_logs)
        streak = Logic.calculate_streak(habit, habit.habit_logs, reference_date)
        {:ok, %{habit: habit, streak: streak}}
    end
  end
end
