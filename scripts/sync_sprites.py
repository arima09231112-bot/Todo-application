#!/usr/bin/env python3
"""art/sprites/ の立ち姿スプライト（{キャラID}.png）を Xcode のアセットカタログ
（Shared/Resources/Assets.xcassets/Characters）に同期する。

art/sprites/ にある PNG をすべて取り込む。キャラを追加・差し替えたら
`python3 scripts/sync_sprites.py` を実行する（xcodegen の再実行は不要）。
アセットカタログ側にしかない古い画像は削除する。
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art" / "sprites"
DST = ROOT / "Shared" / "Resources" / "Assets.xcassets" / "Characters"
INFO = {"author": "xcode", "version": 1}


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    (DST / "Contents.json").write_text(
        json.dumps({"info": INFO, "properties": {"provides-namespace": True}}, indent=2) + "\n"
    )
    sprites = sorted(SRC.glob("*.png"))
    if not sprites:
        raise SystemExit(f"素材がありません: {SRC}/*.png")

    wanted = {f"{png.stem}.imageset" for png in sprites}
    for old in DST.glob("*.imageset"):
        if old.name not in wanted:
            shutil.rmtree(old)

    for png in sprites:
        imageset = DST / f"{png.stem}.imageset"
        imageset.mkdir(exist_ok=True)
        shutil.copy(png, imageset / png.name)
        (imageset / "Contents.json").write_text(
            json.dumps({"images": [{"filename": png.name, "idiom": "universal"}], "info": INFO}, indent=2) + "\n"
        )
    print(f"{len(sprites)} 枚を同期しました -> {DST}")


if __name__ == "__main__":
    main()
