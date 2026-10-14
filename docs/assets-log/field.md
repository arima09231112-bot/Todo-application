# 冒険フィールドの背景

| 項目 | 内容 |
|---|---|
| 元画像 | `art/source/field_day_v1.png`（2000×667、ChatGPT で生成。2026-10-14） |
| 変換 | `python3 -I tools/sprite-pipeline/build_background.py art/source/field_day_v1.png --colors 64 --out art/backgrounds/field_day.png` |
| 結果 | 1ドット≒6.05px → 331×110 ドット、64色。確認画像 `docs/images/field-day-preview.png` |
| 使い方 | ホーム画面下の `PartyField`。幅いっぱいに表示し、下（タブバーの裏）は草の色で埋める。ダークモードは黒を40%重ねて暗くする（夜版の画像ができたら差し替え） |
| 配色の基準 | 空の色 `#41A9FB`（ホーム背景の白→青グラデーションの下端）、草の色 `#5B9C58` |

## プロンプトの方針

- 3:1 の横長。下の約40%はキャラが立つ平らな草地、上は森・山・空
- キャラクター・文字・枠は描かない。アンチエイリアスなし、ベタ塗り
- 既存のゲームの背景に似せない完全オリジナル
