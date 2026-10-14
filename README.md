# RPG型Todoアプリ（iPhone）

日常のタスクを、RPGの冒険に変えるTodoアプリ。Todoを達成するほど勇者（ユーザー）の仲間が増え、パーティが成長していきます。

- 要件定義書: [docs/requirements.md](docs/requirements.md)
- 今後のアイデア: [docs/ideas.md](docs/ideas.md)
- セットアップ（Mac）: [docs/setup.md](docs/setup.md)
- 画面イメージ: [docs/images/concept-v1.png](docs/images/concept-v1.png)
- 対象: iOS 26 以降（SwiftUI / WidgetKit / EventKit / SwiftData）

## 構成

| フォルダ | 内容 |
|---|---|
| `project.yml` | XcodeGen の設定（Xcode プロジェクトの元） |
| `RPGTodo/` | アプリ本体 |
| `RPGTodoWidget/` | ホーム画面ウィジェット |
| `Shared/` | アプリとウィジェットで共有するコード・素材（Assets） |
| `Packages/RPGTodoCore/` | 達成率・パーティ判定などの純Swiftロジック（Linuxでもテスト可能） |
| `art/` | キャラ素材の元画像（`source/`）と整形済みスプライト（`sprites/`） |
| `tools/sprite-pipeline/` | GPT生成画像をスプライトに整形するスクリプト |
| `scripts/` | 素材をXcodeに同期するスクリプトなど |

## 進捗

- [x] 要件定義
- [x] キャラ素材 v1（7体）
- [x] Phase 0: プロジェクトの土台（2026-10-14 実機・ウィジェット・テストで確認済み）
- [x] Phase 1: Todo の基本機能（2026-10-14 実機で確認済み）
- [x] Phase 2: RPGシステム（2026-10-14 実機にインストールして確認。抽選・加入演出・勇者選択）
- [x] Phase 3: ウィジェット（2026-10-14 実機で確認済み）
- [x] Phase 4: カレンダー連携（2026-10-14 実機で確認済み）
- [x] Phase 5: 記録・図鑑（2026-10-14 実機で確認済み）
- [x] 仕上げ①: アプリアイコン・夜の背景（2026-10-14 実機で確認済み）
- [ ] 仕上げ②: 初回起動の勇者選択・通知・カレンダー予定の変更検知など（未着手）
