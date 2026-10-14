# キャラ素材 v2（新デザイン25体）記録

| 版 | 日付 | 元画像 | 生成手段 |
|---|---|---|---|
| v2 | 2026-10-14 | `art/source/cast_sheet_v2.png`（1536×1024、名前札つきの一覧シート。25体） | ChatGPT 画像生成（ユーザーが生成。プロンプトは未記録） |

## 内容と変換

左上から行ごとに左→右の順に、次のIDを付けて変換した。

| 行 | キャラ（ID） |
|---|---|
| 1 | warrior_m, warrior_f, swordsman_m, swordsman_f, mage_m, mage_f, archer_m, archer_f |
| 2 | priest_m, priest_f, thief_m, thief_f, knight_m, knight_f, ninja_m, ninja_f |
| 3 | summoner_m, summoner_f, superstar, slime, golem, dragon, ghost |
| 4 | demonlord_m, demonlord_f |

```bash
python3 -I tools/sprite-pipeline/build_sprites.py art/source/cast_sheet_v2.png \
  --names <上の25個をカンマ区切り> --static --sheet --size 80 --body 78 --tolerance 60 --out <一時フォルダ>
```

- 全キャラ共通の1ドット≒3.20px（各キャラの検出値 3.15〜3.35）を検出し、縮小せず本来のドット数で取り込んだ。
- 出力: `art/sprites/{id}.png`（80×80、輪郭色を含め16色）
- 確認: 25体とも目視で、輪郭・透過・背景の残りなし。名前札は除去されている。

## 勇者

勇者専用の素材は作らず、戦士（男）`warrior_m`・戦士（女）`warrior_f` を勇者として使う（v0.9）。v0.8 で置いていた仮素材 `art/sprites/hero.png` は削除した（元の旧デザインは `art/archive/static-v1/hero.png` に残っている）。

## 旧素材

- `art/archive/static-v1/`: v1（48×48 の静止画。勇者・剣士・魔法使い・僧侶・盗賊・騎士・スーパースター）
- `art/archive/walk-v1/`: v1 の歩行4コマ

## 既知の点

- 既存キャラクターとの類似確認: 未実施（App Store 公開前に実施）。
- 生成時のプロンプトは未記録。次回から記録する。
- スーパースターは、新しい一覧シートの絵（キラキラつき）に置き換えた。

## v0.10: 元の解像度で切り出し直し

ドット化（80×80・16色）した素材はアプリで見るとぼやけたため、同じ一覧シートから**ドットに変換せず元の解像度のまま**切り出し直した（256×256px、`--hires`）。コマンドは `tools/sprite-pipeline/README.md` を参照。ドット化した版は `art/archive/static-v2-dots/` に残している。
