#!/usr/bin/env python3
"""ドット絵の素材を Xcode のアセットカタログ（Shared/Resources/Assets.xcassets）に同期する。

- art/sprites/{キャラID}.png → Characters/{キャラID}
- art/backgrounds/{名前}.png → Backgrounds/{名前}

素材を追加・差し替えたら `python3 scripts/sync_sprites.py` を実行する（xcodegen の再実行は不要）。
アセットカタログ側にしかない古い画像は削除する。
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Shared" / "Resources" / "Assets.xcassets"
GROUPS = [
    (ROOT / "art" / "sprites", CATALOG / "Characters"),
    (ROOT / "art" / "backgrounds", CATALOG / "Backgrounds"),
]
INFO = {"author": "xcode", "version": 1}


def main() -> None:
    for src, dst in GROUPS:
        sync(src, dst)


def sync(src: Path, dst: Path) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    (dst / "Contents.json").write_text(
        json.dumps({"info": INFO, "properties": {"provides-namespace": True}}, indent=2) + "\n"
    )
    sprites = sorted(src.glob("*.png"))
    if not sprites:
        raise SystemExit(f"素材がありません: {src}/*.png")

    wanted = {f"{png.stem}.imageset" for png in sprites}
    for old in dst.glob("*.imageset"):
        if old.name not in wanted:
            shutil.rmtree(old)

    for png in sprites:
        imageset = dst / f"{png.stem}.imageset"
        imageset.mkdir(exist_ok=True)
        shutil.copy(png, imageset / png.name)
        (imageset / "Contents.json").write_text(
            json.dumps({"images": [{"filename": png.name, "idiom": "universal"}], "info": INFO}, indent=2) + "\n"
        )
    print(f"{len(sprites)} 枚を同期しました -> {dst}")


if __name__ == "__main__":
    main()
