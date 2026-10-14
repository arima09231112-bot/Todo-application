# アプリアイコンと夜の背景（2026-10-14）

## アプリアイコン

- コンセプト: ドラクエ風のレトロ RPG の雰囲気。キャラは出さず、青い盾＋金の剣＋白い「✓」（案 E）。有名ゲームのロゴ・紋章は使っていない。
- 元画像: `art/source/app_icon_v1.png`（1254×1254）→ 1024×1024 に縮小して `art/icon/app_icon_1024.png` に保存（透過なし・角は丸めない）。
- 組み込み: `RPGTodo/Resources/Assets.xcassets/AppIcon.appiconset/`（`project.yml` の `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`）。
- 差し替えるときは `art/icon/app_icon_1024.png` と上記フォルダの画像を同じファイル名で置き換える。
- 公開前の確認: 既存ゲームのロゴ・アイコンに似ていないか。

### 生成プロンプト（ChatGPT。案 E）

```
Create an iOS app icon, a square 1024x1024 image, in a retro 16-bit Japanese RPG style.
Background: deep navy night sky with a few tiny pixel stars.
Center: a large blue pixel-art shield with a gold rim and a bold white check mark (✓)
in the middle, and a golden pixel-art sword crossing diagonally behind the shield.
Visible chunky square pixels, limited color palette, hard edges, no anti-aliasing blur.
Keep the main shape large and centered with about 12% margin on every side.
Readable at small sizes. No text, no letters, no characters, no people.
Do not use any existing game logo, emblem or trademark.
Do not draw rounded image corners, borders around the image, or a transparent background:
the image must fill the entire square.
```

実際に出た絵は背景に昼の冒険の景色（山・湖・森）が入った。アプリ内の背景と統一感があるため、そのまま採用した。

## 夜の背景

- 昼の背景（`home_day`）と同じ構図の夜の絵（月・星・月明かりの湖）。`art/source/home_night_v1.png`（941×1672）。
- `art/backgrounds/home_night.png`（そのまま）と `widget_night.png`（幅 540。ウィジェットは画像の大きさに上限があるため）。`scripts/sync_sprites.py` でアセットカタログに同期。
- ダークモードのときに自動で夜の背景に切り替わる（`AdventureBackground`）。ウィジェットも同じ。
- 昼の背景を暗くする補正（`nightDimming`）は廃止した。
