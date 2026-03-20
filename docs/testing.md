# テスト戦略・QAドキュメント

## テスト戦略

### TDD（テスト駆動開発）

本プロジェクトでは TDD を採用する。実装の流れは以下の通り:

1. **Red** — 失敗するテストを先に書く
2. **Green** — テストが通る最小限の実装を書く
3. **Refactor** — テストを壊さずにコードを整理する

実装コードより先にテストを書くことで、関数のインターフェースが使いやすい形に自然と収束し、後からテストを追加する手間も省ける。

### 網羅性の基準: C1 カバレッジ 100%

ブランチカバレッジ（C1）を 100% とする。これにより:

- `if` / `case` / `cond` の全分岐を必ずテストで通過させる
- ガード節、エラーパス、境界条件が漏れなく検証される

> C0（行カバレッジ）だけでは分岐の見落としが起きやすいため C1 を採用する。

### テストケースの洗い出し

**実装着手前にチケット上でテストケースを洗い出す。**

洗い出しには以下の技法を用いる:

#### 同値分割

入力値を「同じ振る舞いをするグループ（同値クラス）」に分け、各クラスから代表値を1つ選んでテストする。

例: `interval_days` のテスト
- 有効クラス: `1`（毎日）、`3`（3日おき）、`7`（週1）
- 無効クラス: `0`、負の値

#### 境界値分析

同値クラスの境界にある値は不具合が発生しやすいため、境界の前後を重点的にテストする。

例: ストリーク判定の境界
- 「直近の予定日」当日 → ストリーク継続
- 「1つ前の予定日」→ イエスタデイ・チェックイン（継続）
- 「2つ前の予定日」→ ストリーク切れ

### テストケースの優先順位

洗い出したテストケースには以下の観点で優先順位をつける:

1. **ドメインの核心ロジック**（ストリーク計算、target_date 判定）— 最優先
2. **エラーパス**（重複ログ、不正入力）— 高
3. **UI / コントローラー層**（レンダリング、リダイレクト）— 中

---

## テスト実行手順

### 通常実行（全テスト）

```bash
mix test
```

### 特定ファイルのみ実行

```bash
mix test test/habit_wave_web/habits/logic_test.exs
```

### 特定のテストケースのみ実行

```bash
mix test test/habit_wave_web/habits/logic_test.exs:24
```

行番号で `describe` ブロックや個別 `test` を指定できる。

### 失敗時のリセット

テストDBに不整合が生じた場合（後述）は以下を実行する:

```bash
mix ecto.reset
```

これで `drop → create → migrate` が一括実行され、DBがクリーンな状態に戻る。

---

## SQL Sandbox の仕組み

### 概要

Phoenix / Ecto のテストは **SQL Sandbox** を使ってDBを分離する。
各テストが開始するとトランザクションが開かれ、テスト終了時に**必ずロールバック**される。
これにより、テスト同士がDBの状態を汚染しない。

### 設定場所

`test/test_helper.exs`:
```elixir
Ecto.Adapters.SQL.Sandbox.mode(HabitWaveWeb.Repo, :manual)
```

`test/support/data_case.ex`:
```elixir
def setup_sandbox(tags) do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(HabitWaveWeb.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
end
```

`use HabitWaveWeb.DataCase` を使うテストモジュールは、`setup` で自動的にサンドボックスが起動・クリーンアップされる。

### async: true の挙動

| 設定 | サンドボックスモード | 備考 |
|---|---|---|
| `async: true` | 各テストが独立したトランザクション（並列実行可） | DBアクセスするテストで推奨 |
| `async: false` | 共有トランザクション（直列実行） | LiveViewテストなど一部で必要 |

純粋関数のみテストする `logic_test.exs` は `use ExUnit.Case, async: true`（DataCase不要）。

---

## テストDBに手動データが残る原因と対処法

### 原因

以下のいずれかのケースで、サンドボックスの外側にデータが書き込まれることがある:

1. **`iex -S mix` や `mix run` でテストDBに直接接続して操作した**
   - `MIX_ENV=test iex -S mix` などを実行し、DB操作をした場合、サンドボックスは使われないためデータが永続化される。

2. **テストプロセスがクラッシュしてロールバックされなかった**
   - 稀に、テストプロセスが異常終了するとトランザクションがコミットされたままになることがある。

3. **`DataCase` を使わずにDBを操作するテストを書いた**
   - `use ExUnit.Case` のみでEctoのCRUDを呼び出した場合、サンドボックスが有効にならない。

### 症状

- `mix test` を再実行すると「一意制約違反」や「レコードが既に存在する」といったエラーが出る。
- あるテストが別のテストのデータに依存してしまう（順序依存）。

### 対処法

```bash
mix ecto.reset
```

テストDBを完全にリセットする。開発DBには影響しない（`MIX_ENV=test` が自動で適用される）。

---

## テストの種類と配置

| 種類 | 配置場所 | 使うベースモジュール |
|---|---|---|
| ドメインロジック（純粋関数） | `test/habit_wave_web/habits/logic_test.exs` | `ExUnit.Case` |
| Contextレイヤー（DB含む） | `test/habit_wave_web/habits_test.exs` | `HabitWaveWeb.DataCase` |
| LiveViewテスト | `test/habit_wave_web_web/live/` | `HabitWaveWeb.ConnCase` |
| コントローラーテスト | `test/habit_wave_web_web/controllers/` | `HabitWaveWeb.ConnCase` |

---

## よくある落とし穴

### `async: true` と LiveView の組み合わせ

LiveViewテストは内部でプロセスをスポーンするため、`async: true` を使うと不安定になることがある。LiveViewテストでは `async: false` を維持する。

### `create_user` の重複

`habits_test.exs` のヘルパー `create_user/0` は `System.unique_integer/0` でメールアドレスを一意にしている。
同じセッション内で複数のテストが並列実行されても衝突しない。

### 日付固定のテスト

ストリーク計算など日付に依存するロジックのテストは、**必ず日付を明示的に引数として渡す**。
`Date.utc_today()` などを内部で呼ぶテストは環境に依存するため、ロジック関数は日付を引数で受け取る設計にしている（`logic.ex` 参照）。
