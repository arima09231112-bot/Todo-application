#!/usr/bin/env python3
"""art/sprites/ のスプライトを Xcode のアセットカタログ（Shared/Resources/Assets.xcassets）に同期する。

素材を差し替えたら `python3 scripts/sync_sprites.py` を実行し、xcodegen は再実行しなくてよい
（アセットカタログの中身が変わるだけ）。
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art" / "sprites"
DST = ROOT / "Shared" / "Resources" / "Assets.xcassets" / "Characters"
IDS = ["hero", "swordsman", "mage", "priest", "thief", "knight", "superstar"]
FRAMES = 4
INFO = {"author": "xcode", "version": 1}


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    (DST / "Contents.json").write_text(
        json.dumps({"info": INFO, "properties": {"provides-namespace": True}}, indent=2) + "\n"
    )
    for cid in IDS:
        for frame in range(FRAMES):
            name = f"{cid}_right_{frame}"
            source = SRC / cid / f"{name}.png"
            if not source.exists():
                raise SystemExit(f"素材がありません: {source}")
            imageset = DST / f"{name}.imageset"
            imageset.mkdir(exist_ok=True)
            shutil.copy(source, imageset / f"{name}.png")
            (imageset / "Contents.json").write_text(
                json.dumps({"images": [{"filename": f"{name}.png", "idiom": "universal"}], "info": INFO}, indent=2)
                + "\n"
            )
    print(f"{len(IDS) * FRAMES} 枚を同期しました -> {DST}")


if __name__ == "__main__":
    main()
