#!/usr/bin/env python3
"""ChatGPT で作った「ドット絵風」の背景画像を、本物のドット絵（1ドット = 1ピクセル）に変換する。

キャラ用の build_sprites.py と同じ方法（1ドットの大きさの自動検出 → 減色 → ブロックごとの最頻色）で縮小する。
背景なので透過・輪郭線の付与はしない。

    python3 -I tools/sprite-pipeline/build_background.py art/source/field_day_v1.png \
        --out art/backgrounds/field_day.png
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_sprites  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--colors", type=int, default=32, help="色数の上限")
    parser.add_argument("--cell-size", type=float, help="1ドットの大きさ(px)。省略時は自動検出")
    parser.add_argument("--preview-scale", type=int, default=4)
    args = parser.parse_args()

    source = Image.open(args.input).convert("RGBA")
    cell = args.cell_size or build_sprites.detect_cell_size([source])
    [pixels] = build_sprites.downscale([source], 1 / cell, args.colors)
    result = Image.fromarray(pixels).convert("RGB")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.out)
    preview = args.out.with_name(args.out.stem + "_preview.png")
    result.resize((result.width * args.preview_scale, result.height * args.preview_scale), Image.NEAREST).save(preview)
    print(f"1ドット≒{cell:.2f}px → {result.width}×{result.height} ドット、{len(result.getcolors(1 << 16))}色: {args.out}")


if __name__ == "__main__":
    main()
