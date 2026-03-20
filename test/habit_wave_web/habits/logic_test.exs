defmodule HabitWaveWeb.Habits.LogicTest do
  use ExUnit.Case, async: true
  alias HabitWaveWeb.Habits.{Logic, Habit, HabitLog}

  describe "generate_scheduled_dates/3" do
    test "daily habits" do
      result = Logic.generate_scheduled_dates(~D[2026-01-01], 1, ~D[2026-01-05])
      assert length(result) == 5
      assert List.first(result) == ~D[2026-01-01]
      assert List.last(result) == ~D[2026-01-05]
    end

    test "3-day interval habits" do
      result = Logic.generate_scheduled_dates(~D[2026-01-01], 3, ~D[2026-01-10])
      assert result == [~D[2026-01-01], ~D[2026-01-04], ~D[2026-01-07], ~D[2026-01-10]]
    end

    test "weekly habits" do
      result = Logic.generate_scheduled_dates(~D[2026-01-01], 7, ~D[2026-01-22])
      assert result == [~D[2026-01-01], ~D[2026-01-08], ~D[2026-01-15], ~D[2026-01-22]]
    end
  end

  describe "calculate_streak/3 - daily habits" do
    test "returns 0 when no logs exist" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 1}
      result = Logic.calculate_streak(habit, [], ~D[2026-01-05])
      assert result.current_streak == 0
    end

    test "returns 1 when only today is logged" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 1}
      logs = [%HabitLog{target_date: ~D[2026-01-05]}]
      result = Logic.calculate_streak(habit, logs, ~D[2026-01-05])
      assert result.current_streak == 1
    end

    test "counts consecutive days" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 1}
      logs = [
        %HabitLog{target_date: ~D[2026-01-05]},
        %HabitLog{target_date: ~D[2026-01-04]},
        %HabitLog{target_date: ~D[2026-01-03]}
      ]
      result = Logic.calculate_streak(habit, logs, ~D[2026-01-05])
      assert result.current_streak == 3
    end

    test "yesterday tolerance - allows previous day" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 1}
      logs = [%HabitLog{target_date: ~D[2026-01-04]}]
      result = Logic.calculate_streak(habit, logs, ~D[2026-01-05])
      assert result.current_streak == 1
      assert result.is_on_track == true
    end
  end

  describe "calculate_streak/3 - interval habits (3 days)" do
    test "counts consecutive scheduled dates" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 3}
      logs = [
        %HabitLog{target_date: ~D[2026-01-10]},
        %HabitLog{target_date: ~D[2026-01-07]},
        %HabitLog{target_date: ~D[2026-01-04]}
      ]
      result = Logic.calculate_streak(habit, logs, ~D[2026-01-10])
      assert result.current_streak == 3
    end

    test "yesterday tolerance - allows previous scheduled date" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 3}
      logs = [%HabitLog{target_date: ~D[2026-01-07]}]
      result = Logic.calculate_streak(habit, logs, ~D[2026-01-10])
      assert result.current_streak == 1
    end

    test "breaks when scheduled date is missed" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 3}
      logs = [
        %HabitLog{target_date: ~D[2026-01-10]},
        %HabitLog{target_date: ~D[2026-01-04]}
      ]
      result = Logic.calculate_streak(habit, logs, ~D[2026-01-10])
      assert result.current_streak == 1
    end
  end

  describe "determine_target_date/2" do
    test "returns current scheduled date when today is scheduled" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 3}
      assert {:ok, ~D[2026-01-07]} = Logic.determine_target_date(habit, ~D[2026-01-07])
    end

    test "returns previous scheduled date for yesterday tolerance" do
      habit = %Habit{start_date: ~D[2026-01-01], interval_days: 3}
      assert {:ok, ~D[2026-01-07]} = Logic.determine_target_date(habit, ~D[2026-01-08])
    end
  end
end
