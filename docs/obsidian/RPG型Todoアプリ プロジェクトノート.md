---
title: RPG型Todoアプリ プロジェクトノート
created: 2026-10-13
tags:
  - project
  - ios
  - rpg-todo
status: Phase 0（Mac での動作確認中）
---

# RPG型Todoアプリ プロジェクトノート

日常のタスクを、RPGの冒険に変える iPhone アプリ。Todo を達成するほど勇者（ユーザー）の仲間が増える。

## リンク

- リポジトリ: https://github.com/arima09231112-bot/Todo-application
- 作業ブランチ: `claude/rpg-todo-app-requirements-7crz4u`
- 要件定義書（v0.6）: `docs/requirements.md`
- Mac のセットアップ手順: `docs/setup.md`
- 画面イメージ: `docs/images/concept-v1.png`

## 決まったこと

| 項目 | 決定 |
|---|---|
| 対応OS | iOS 26 以上（Xcode 26.5 のため。当初の iOS 27 から変更） |
| 技術 | SwiftUI / WidgetKit / SwiftData / EventKit / App Intents、Xcode プロジェクトは XcodeGen で生成 |
| 配布 | 当面は自分専用。完成度次第で App Store 公開（公開できる品質・権利で作る） |
| 1日の区切り | 0:00 |
| 未完了Todo | 自動繰り越しなし。手動で「今日に移す」 |
| 繰り返しTodo | MVP に含める（毎日・平日・曜日指定） |
| カレンダー候補 | 端末内テンプレート方式（AI は次期） |
| ダークモード | 対応（システム追従） |
| 完了チェックの色 | 青（当面。後から変えやすくしておく） |
| タブ | ホーム / カレンダー / 記録 / 設定 |
| 左上のボタン | キャラクター図鑑 |
| 加入演出 | 節目ごとに1日1回 |

## パーティのルール

| 達成率 | パーティ |
|---|---|
| 0〜19% | 勇者のみ |
| 20% ごと | 剣士 → 魔法使い → 僧侶 → 盗賊 → 騎士 の順に加入 |
| 100% | 勇者＋仲間5人（6人） |
| 100% の日にまれに | スーパースター（7人目、レアキャラ） |

- 達成率 = 完了数 ÷ 当日のTodo総数 × 100（切り捨て）。0件のときは「今日の冒険は準備中」。
- スーパースターの抽選（**仮**）: その日に初めて100%になったとき1回だけ、確率10%。10回続けて外れたら次は必ず出る。

## キャラ素材

- 7体（勇者・剣士・魔法使い・僧侶・盗賊・騎士・スーパースター）の v1 が完成。48×48ドット、16色以内、右向き、歩行4コマ。
- ChatGPT で生成 → `tools/sprite-pipeline/` のスクリプトで自動整形（エディタは使わない）。
- 素材の置き場: `art/sprites/<キャラ名>/`、Xcode 用は `Shared/Resources/Assets.xcassets`（`python3 scripts/sync_sprites.py` で同期）。
- 制作ルールはスキル `.claude/skills/pixel-art-character/` にまとめてある。

## 進捗

- [x] 要件定義（v0.6）
- [x] キャラ素材 v1（7体）
- [x] Phase 0 のファイル一式（`project.yml`、アプリ、ウィジェット、`RPGTodoCore`）
- [ ] Phase 0 の Mac での確認（`xcodegen` → ビルド → iPhone で実行）
- [ ] Phase 1: Todo 基本機能＋繰り返し
- [ ] Phase 2: パーティ表示・歩行アニメーション・加入演出・図鑑の素材取り込み
- [ ] Phase 3: ウィジェット
- [ ] Phase 4: カレンダー連携
- [ ] Phase 5: 記録・図鑑・仕上げ

## 次にやること（Mac）

1. リポジトリを Mac に取り込む（Xcode の Clone Git Repository）
2. Mac 上で動く Claude のセッションを新しく始め、`docs/setup.md` に沿って Phase 0 を確認する
3. `project.yml` の次の3つを自分の値に変える
   - バンドルID（例 `com.yourname.RPGTodo`、ウィジェットは末尾に `.Widget`）
   - App Group 名（例 `group.com.yourname.RPGTodo`）
   - Apple ID のチームID
4. `xcodegen` → `open RPGTodo.xcodeproj` → アプリとウィジェットで Team を選ぶ → iPhone で実行
5. 画面に「App Group: OK」（緑）が出れば Phase 0 完了

## 未確認・未解決

- Phase 0 のビルドとテストは **まだ一度も実行していない**（作業環境に Swift がなかったため）。
- スーパースターの確率10%・天井10回は仮の値。使いながら調整する。
- 騎士の歩行4ポーズで、盾が4コマ目にしか描かれていない（今は直さず進める）。
- 勇者の見た目は、有名キャラを連想させないよう「赤いハチマキ＋青緑のチュニック」に変更済み。App Store 公開前に、全キャラが既存キャラに似ていないか確認する。
- ChatGPT で素材を生成したときのプロンプトは未記録。次回から `docs/assets-log/` に残す。
- フィールド背景・ホーム上部の城と山・演出用エフェクトの絵は未作成（仮の絵で進められる）。

## 作業の進め方メモ

- コードを書くときは軽いモデルに切り替えてよい。難しい設計判断や不具合調査のときだけ上位モデルに戻す。
- 仕様の正は `docs/requirements.md`。食い違ったらこちらを優先する。
- 確認が必要な作業（Xcode の実行など）は Mac 上のセッションで行う。クラウドのセッションからは Mac を操作できない。
