defmodule HabitWaveWeb.Habits.Logic do
  @moduledoc """
  Pure functions for habit streak calculation with n-day interval support.
  Implements "yesterday tolerance" (イエスタデイ・チェックイン) logic.
  """

  alias HabitWaveWeb.Habits.{Habit, HabitLog}

  @type streak_result :: %{
          current_streak: non_neg_integer(),
          is_on_track: boolean(),
          next_scheduled_date: Date.t() | nil
        }

  @doc """
  Calculates current streak for a habit with interval_days support.

  ## Algorithm
  1. Generate all scheduled dates from start_date to reference_date
  2. Find latest log entry
  3. Check if latest log is for current OR previous scheduled date (yesterday tolerance)
  4. Count consecutive scheduled dates backward

  ## Examples
      iex> habit = %Habit{start_date: ~D[2026-01-01], interval_days: 3}
      iex> logs = [%HabitLog{target_date: ~D[2026-01-07]}, %HabitLog{target_date: ~D[2026-01-04]}]
      iex> calculate_streak(habit, logs, ~D[2026-01-10])
      %{current_streak: 2, is_on_track: true, next_scheduled_date: ~D[2026-01-10]}
  """
  @spec calculate_streak(Habit.t(), [HabitLog.t()], Date.t()) :: streak_result()
  def calculate_streak(%Habit{} = habit, logs, reference_date) do
    scheduled_dates = generate_scheduled_dates(habit.start_date, habit.interval_days, reference_date)
    sorted_scheduled = Enum.sort(scheduled_dates, {:desc, Date})

    logged_dates =
      logs
      |> Enum.map(& &1.target_date)
      |> Enum.uniq()
      |> Enum.sort({:desc, Date})

    current_scheduled = List.first(sorted_scheduled)
    previous_scheduled = Enum.at(sorted_scheduled, 1)
    latest_log = List.first(logged_dates)

    streak =
      cond do
        latest_log == nil ->
          0

        latest_log == current_scheduled ->
          count_consecutive_streak(logged_dates, sorted_scheduled)

        latest_log == previous_scheduled ->
          # Yesterday tolerance: count from previous scheduled date
          count_consecutive_streak(logged_dates, Enum.drop(sorted_scheduled, 1))

        true ->
          0
      end

    %{
      current_streak: streak,
      is_on_track: streak > 0,
      next_scheduled_date: current_scheduled
    }
  end

  @doc """
  Generates all scheduled dates for a habit from start_date to end_date.
  """
  @spec generate_scheduled_dates(Date.t(), pos_integer(), Date.t()) :: [Date.t()]
  def generate_scheduled_dates(start_date, interval_days, end_date) do
    Stream.iterate(start_date, &Date.add(&1, interval_days))
    |> Stream.take_while(&(Date.compare(&1, end_date) != :gt))
    |> Enum.to_list()
  end

  @doc """
  Determines which target_date to use for recording (supports yesterday tolerance).

  Returns the most recent scheduled date that is <= reference_date,
  or the next upcoming scheduled date if reference_date is within tolerance.
  """
  @spec determine_target_date(Habit.t(), Date.t()) :: {:ok, Date.t()} | {:error, :no_valid_target}
  def determine_target_date(%Habit{} = habit, reference_date) do
    # Generate all scheduled dates up to and including some future dates
    end_date = Date.add(reference_date, habit.interval_days)
    scheduled_dates = generate_scheduled_dates(habit.start_date, habit.interval_days, end_date)

    # Find the most recent scheduled date that's <= reference_date
    past_and_current = Enum.filter(scheduled_dates, &(Date.compare(&1, reference_date) != :gt))

    case past_and_current do
      [] -> {:error, :no_valid_target}
      dates -> {:ok, List.last(dates)}
    end
  end

  # Private: counts consecutive scheduled dates that have logs
  defp count_consecutive_streak(logged_dates, scheduled_dates) do
    scheduled_dates
    |> Enum.take_while(&Enum.member?(logged_dates, &1))
    |> Enum.count()
  end
end
