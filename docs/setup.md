# 開発環境のセットアップ（Mac）

## 1. 事前準備

- Xcode 26 以降（iOS 26 SDK。Mac の Xcode が 26.5 のため、対応OSを 27 から 26 に下げた）
- XcodeGen: `brew install xcodegen`

## 2. 自分用の設定を変える（初回のみ）

`project.yml` の次の3か所を、自分の値に変更します。

| 場所 | 例 | 説明 |
|---|---|---|
| `options.bundleIdPrefix` と各 `PRODUCT_BUNDLE_IDENTIFIER` | `com.yourname.RPGTodo` | アプリの識別子。ウィジェットは末尾に `.Widget` を付ける |
| `settings.base.APP_GROUP_ID` | `group.com.yourname.RPGTodo` | アプリとウィジェットでデータを共有するグループ名（`group.` で始める） |
| `settings.base.DEVELOPMENT_TEAM` | `ABCDE12345` | Apple ID のチームID。空のままでも、Xcode の Signing & Capabilities で選べば動く |

## 3. プロジェクトを生成して実行する

```bash
xcodegen            # RPGTodo.xcodeproj と Config/ を生成
open RPGTodo.xcodeproj
```

1. Xcode で `RPGTodo` と `RPGTodoWidget` の両方のターゲットで、Signing & Capabilities の Team を選ぶ
2. 実機の iPhone をつなぎ、スキーム `RPGTodo` を実行する
3. 画面に「今日の冒険」と7体のキャラが出て、**「App Group: OK」（緑）**と表示されれば成功
4. ホーム画面を長押し →「＋」→「RPG Todo」→ 小サイズを追加し、勇者の画像と「App Group: OK」が出れば成功

「App Group: 未設定」（赤）と出る場合は、アプリとウィジェットの両方で Signing & Capabilities に App Groups が入っていて、同じグループ名にチェックが付いているか確認してください。

## 4. よく使う操作

| やりたいこと | コマンド |
|---|---|
| project.yml を変更した | `xcodegen` を再実行 |
| キャラ素材を差し替えた | `python3 scripts/sync_sprites.py`（Xcode は再生成不要） |
| 共通ロジックのテスト | `cd Packages/RPGTodoCore && swift test` |

`RPGTodo.xcodeproj` と `Config/` は生成物なので Git には入れていません。
