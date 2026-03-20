---
name: issue
description: GitHub issueをfeat/fix/taskテンプレートで作成する
argument-hint: <feat|fix|task> <title>
---

## 手順

### 1. ラベルの確認・作成

まず `gh label list` でラベル一覧を確認し、不足しているラベルを作成する:

```
gh label create "feat" --color "0075ca" --description "新機能"
gh label create "fix"  --color "d73a4a" --description "バグ修正"
gh label create "task" --color "e4e669" --description "作業・調査・設定"
```

既に存在するラベルはスキップする。

### 2. 引数の解釈

`$ARGUMENTS` から type と title を取得する。
- 第1引数: `feat` / `fix` / `task`
- 残り: issue タイトル

### 3. 内容の確認

概要・目的・完了条件をユーザーに確認する（引数に含まれていない場合）。

### 4. issue 作成

以下のフォーマットで作成する:

```
gh issue create \
  --title "<type>: <title>" \
  --label "<type>" \
  --body "## 概要
<概要>

## 目的
<目的>

## 完了条件
- [ ] <条件>"
```
