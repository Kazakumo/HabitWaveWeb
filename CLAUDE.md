# Habit Wave (ゆらり) - Project Guidelines

## Concept
「完璧主義を捨て、ゆらゆらと習慣を続ける」ためのWeb版習慣トラッカー。
n日に1回の習慣に対応し、イエスタデイ・チェックイン（寛容な記録）を許容する。

## Tech Stack
- Erlang/OTP 28 / Elixir 1.19.4 /  Phoenix 1.8.3 (LiveView)
- Database: PostgreSQL / Ecto
- Authentication: phx.gen.auth + Assent (Google OAuth)

## Domain Logic: Streak Calculation
- `interval_days`: 習慣の間隔（1=毎日, 3=3日に1回）
- `start_date`: ストリーク判定の起点
- 判定ロジック:
    - 今日の日付が `(today - start_date) % interval_days == 0` なら予定日。
    - ストリーク維持条件: 「直近の予定日」または「その1つ前の予定日」に記録があること。
    - 記録（HabitRecord）は、実際の記録日ではなく「対象とする予定日（target_date）」を保持する。

## Module Namespace ルール
プロジェクト名が `habit_wave_web` のため、Phoenixの命名規則により以下の2つのモジュール空間が存在する：
- `HabitWaveWeb` — ビジネスロジック層（Context、Schema、純粋関数）
- `HabitWaveWebWeb` — Web層（LiveView、Controller、Component、Router）

Web層のファイル（`lib/habit_wave_web_web/` 以下）では必ず `use HabitWaveWebWeb, :live_view` / `:live_component` / `:controller` を使うこと。`use HabitWaveWeb` は誤り。

## Implementation Patterns
- Business Logic: `lib/habit_wave_web/habits/logic.ex` に純粋関数として記述。
- Contexts: `lib/habit_wave_web/habits.ex` (Habit, HabitLogのCRUD)
- LiveView: `lib/habit_wave_web_web/live/`

## Style Guide
- 型定義: `@type` を積極的に使用し、型安全性を高める。
- テスト: `test/habit_wave/habits_logic_test.exs` でロジックの境界値を網羅する。
- 命名: スネークケース、Elixirの標準的な命名規則に従う。