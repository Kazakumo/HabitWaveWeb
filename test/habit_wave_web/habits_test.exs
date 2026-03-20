defmodule HabitWaveWeb.HabitsTest do
  use HabitWaveWeb.DataCase, async: true
  alias HabitWaveWeb.{Habits, Repo, Accounts}
  alias HabitWaveWeb.Habits.{Habit, HabitLog}

  defp create_user do
    {:ok, user} = Accounts.register_user(%{
      email: "test#{System.unique_integer()}@example.com",
      password: "password123456"
    })
    user
  end

  describe "create_habit/2" do
    test "creates habit with settings" do
      user = create_user()
      {:ok, habit} = Habits.create_habit(%{
        "title" => "Exercise",
        "start_date" => ~D[2026-01-01],
        "interval_days" => 1
      }, user.id)

      habit = Repo.preload(habit, :settings)
      assert habit.title == "Exercise"
      assert habit.settings != nil
    end
  end

  describe "log_habit/3" do
    test "creates log for scheduled date" do
      user = create_user()
      {:ok, habit} = Habits.create_habit(%{
        "title" => "Daily",
        "start_date" => ~D[2026-01-01],
        "interval_days" => 1
      }, user.id)

      {:ok, log} = Habits.log_habit(habit, 1.0, ~D[2026-01-05])
      assert log.target_date == ~D[2026-01-05]
    end

    test "prevents duplicate logs" do
      user = create_user()
      {:ok, habit} = Habits.create_habit(%{
        "title" => "Daily",
        "start_date" => ~D[2026-01-01],
        "interval_days" => 1
      }, user.id)

      {:ok, _} = Habits.log_habit(habit, 1.0, ~D[2026-01-05])
      assert {:error, :already_logged} = Habits.log_habit(habit, 1.0, ~D[2026-01-05])
    end
  end

  describe "get_habit_with_streak/3" do
    test "calculates streak correctly" do
      user = create_user()
      {:ok, habit} = Habits.create_habit(%{
        "title" => "Daily",
        "start_date" => ~D[2026-01-01],
        "interval_days" => 1
      }, user.id)

      {:ok, _} = Habits.log_habit(habit, 1.0, ~D[2026-01-05])
      {:ok, _} = Habits.log_habit(habit, 1.0, ~D[2026-01-04])
      {:ok, _} = Habits.log_habit(habit, 1.0, ~D[2026-01-03])

      {:ok, result} = Habits.get_habit_with_streak(habit.id, user.id, ~D[2026-01-05])
      assert result.streak.current_streak == 3
    end
  end
end
