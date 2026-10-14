# superstar（スーパースター）素材記録

| 版 | 日付 | 元画像 | 生成手段 | 出力 |
|---|---|---|---|---|
| v1 | 2026-10-13 | `art/source/superstar_walk_v1.png`（2172×724、歩行4ポーズ） | ChatGPT 画像生成（ユーザーが生成。プロンプトは未記録） | `art/sprites/superstar/superstar_right_0..3.png`（48×48、16色、1ドット≒10.75px を検出し縦41ドットで取り込み） |

- 変換コマンド: `python3 -I tools/sprite-pipeline/build_sprites.py art/source/superstar_walk_v1.png --names superstar --walk-frames --out art/sprites/superstar`
- 既存キャラクターとの類似確認: 未実施（App Store 公開前に実施）
- 次回の生成時は、使ったプロンプトをこのファイルに追記する

## v0.7 の変更（歩行アニメーション廃止）

- アプリで使う素材は**立ち姿の静止画1枚** `art/sprites/{id}.png` に変更した。元の歩行4コマは `art/archive/walk-v1/{id}/` に保管（アプリでは使わない）。
- 静止画は歩行4コマの1コマ目をそのまま使用。ただし騎士だけは、盾が描かれている4コマ目を使用（1〜3コマ目は盾が欠けていたため）。
