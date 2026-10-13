#!/usr/bin/env python3
"""GPT などで生成した「ドット絵風」画像を、アプリで使えるスプライトに自動整形する。

手作業（ドット絵エディタ）なしで、次の処理をまとめて行う。

1. 背景の除去（画像の外周から背景色を塗りつぶし判定。キャラ内部の白は残す）
2. キャラごとの切り出し（1枚に複数キャラが並んでいても自動で分割）
3. 指定サイズ（既定 32x32）への縮小と減色（既定 16 色）
4. 濃色の輪郭線の付与（小さく表示しても背景から浮かせる）
5. 歩行アニメーション 4 フレームの自動生成（上下の揺れ＋足の踏み出し）
6. 確認用のプレビュー（拡大 PNG と歩行 GIF）

使い方:
    python3 build_sprites.py INPUT.png --names hero,swordsman,mage --out OUT_DIR

必要ライブラリ: Pillow, numpy
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

TRANSPARENT = (0, 0, 0, 0)


def estimate_background(rgb: np.ndarray) -> np.ndarray:
    """外周のピクセルの中央値を背景色とみなす。"""
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    return np.median(border, axis=0)


def background_mask(rgb: np.ndarray, tolerance: float) -> np.ndarray:
    """外周から連結している「背景に近い色」の領域を True で返す。"""
    h, w, _ = rgb.shape
    bg = estimate_background(rgb)
    near_bg = np.linalg.norm(rgb.astype(float) - bg, axis=2) < tolerance
    mask = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(w):
        queue.extend([(0, x), (h - 1, x)])
    for y in range(h):
        queue.extend([(y, 0), (y, w - 1)])
    while queue:
        y, x = queue.popleft()
        if mask[y, x] or not near_bg[y, x]:
            continue
        mask[y, x] = True
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and not mask[ny, nx]:
                queue.append((ny, nx))
    return mask


def find_characters(foreground: np.ndarray, min_area: int) -> list[tuple[int, int, int, int]]:
    """前景の連結成分を探し、左から順にバウンディングボックス (x0, y0, x1, y1) を返す。"""
    h, w = foreground.shape
    seen = np.zeros_like(foreground)
    boxes = []
    for sy in range(h):
        for sx in range(w):
            if not foreground[sy, sx] or seen[sy, sx]:
                continue
            queue = deque([(sy, sx)])
            seen[sy, sx] = True
            ys, xs = [], []
            while queue:
                y, x = queue.popleft()
                ys.append(y)
                xs.append(x)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < w and foreground[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            queue.append((ny, nx))
            if len(ys) >= min_area:
                boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    boxes.sort(key=lambda b: b[0])
    return merge_overlapping_columns(boxes)


def merge_overlapping_columns(boxes: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    """横方向に重なる成分（帽子の飾りや武器などの離れたパーツ）を1体にまとめる。"""
    merged: list[list[int]] = []
    for x0, y0, x1, y1 in boxes:
        if merged and x0 <= merged[-1][2]:
            m = merged[-1]
            m[0], m[1], m[2], m[3] = min(m[0], x0), min(m[1], y0), max(m[2], x1), max(m[3], y1)
        else:
            merged.append([x0, y0, x1, y1])
    return [tuple(m) for m in merged]


def to_sprite(rgba: Image.Image, size: int, body: int, colors: int) -> Image.Image:
    """切り出したキャラを size x size のキャンバスに、高さ body ピクセルで収める。"""
    w, h = rgba.size
    scale = body / max(w, h)
    small = rgba.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.BOX)

    arr = np.array(small)
    alpha = arr[:, :, 3] >= 128
    rgb = Image.fromarray(arr[:, :, :3]).quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    rgb = np.array(rgb.convert("RGB"))
    out = np.zeros((*alpha.shape, 4), dtype=np.uint8)
    out[alpha, :3] = rgb[alpha]
    out[alpha, 3] = 255

    canvas = Image.new("RGBA", (size, size), TRANSPARENT)
    sw, sh = small.size
    # 足元をキャンバスの下端から 1px 上にそろえる（輪郭線のぶん）
    canvas.paste(Image.fromarray(out), ((size - sw) // 2, size - sh - 1))
    return add_outline(canvas)


def add_outline(sprite: Image.Image) -> Image.Image:
    """キャラの外側 1px に、隣接する色を暗くした輪郭を付ける。"""
    arr = np.array(sprite)
    opaque = arr[:, :, 3] > 0
    out = arr.copy()
    h, w = opaque.shape
    for y in range(h):
        for x in range(w):
            if opaque[y, x]:
                continue
            neighbors = [
                arr[ny, nx, :3]
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1))
                if 0 <= ny < h and 0 <= nx < w and opaque[ny, nx]
            ]
            if neighbors:
                dark = (np.mean(neighbors, axis=0) * 0.25).astype(np.uint8)
                out[y, x, :3] = dark
                out[y, x, 3] = 255
    return Image.fromarray(out)


def walk_frames(sprite: Image.Image, leg_ratio: float = 0.22) -> list[Image.Image]:
    """直立スプライトから歩行 4 フレーム（直立 / 右足前 / 直立 / 左足前）を作る。

    下から leg_ratio の範囲を「足」とみなし、前側／後ろ側の足を交互に 1px 踏み出す。
    足を踏み出すフレームでは上半身を 1px 持ち上げて、歩く揺れを出す。
    """
    arr = np.array(sprite)
    h, w, _ = arr.shape
    rows = np.where(arr[:, :, 3].any(axis=1))[0]
    top, bottom = rows.min(), rows.max() + 1
    leg_top = bottom - max(2, round((bottom - top) * leg_ratio))
    cols = np.where(arr[leg_top:bottom, :, 3].any(axis=0))[0]
    mid = (cols.min() + cols.max() + 1) // 2

    def shift(block: np.ndarray, dx: int) -> np.ndarray:
        out = np.zeros_like(block)
        if dx > 0:
            out[:, dx:] = block[:, :-dx]
        elif dx < 0:
            out[:, :dx] = block[:, -dx:]
        else:
            out[:] = block
        return out

    def stride(direction: int) -> Image.Image:
        frame = np.zeros_like(arr)
        frame[: leg_top - 1] = arr[1:leg_top]  # 上半身を 1px 上へ
        frame[leg_top - 1] = arr[leg_top - 1]
        # 片足だけを進行方向（または逆）へ 1px ずらし、元の足の上に重ねる（隙間を作らない）
        legs = arr[leg_top:bottom]
        moving = legs.copy()
        if direction > 0:
            moving[:, :mid] = 0
        else:
            moving[:, mid:] = 0
        moving = shift(moving, direction)
        frame[leg_top:bottom] = np.where(moving[:, :, 3:4] > 0, moving, legs)
        return Image.fromarray(frame)

    return [sprite, stride(1), sprite, stride(-1)]


def preview(frames_by_name: dict[str, list[Image.Image]], out_dir: Path, scale: int) -> None:
    names = list(frames_by_name)
    size = frames_by_name[names[0]][0].size[0]
    cell = size * scale

    sheet = Image.new("RGBA", (cell * 4, cell * len(names)), (238, 244, 252, 255))
    for row, name in enumerate(names):
        for col, frame in enumerate(frames_by_name[name]):
            big = frame.resize((cell, cell), Image.NEAREST)
            sheet.alpha_composite(big, (col * cell, row * cell))
    sheet.save(out_dir / "preview_sheet.png")

    # 隊列で歩く様子の GIF（アプリのホーム画面下部のイメージ）
    gif_frames = []
    for i in range(4):
        strip = Image.new("RGBA", (cell * len(names), cell), (196, 228, 160, 255))
        for col, name in enumerate(names):
            frame = frames_by_name[name][(i + col) % 4]
            strip.alpha_composite(frame.resize((cell, cell), Image.NEAREST), (col * cell, 0))
        gif_frames.append(strip.convert("RGB"))
    gif_frames[0].save(
        out_dir / "preview_walk.gif", save_all=True, append_images=gif_frames[1:], duration=150, loop=0
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument("--names", required=True, help="左から順のキャラID（カンマ区切り）")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--size", type=int, default=32, help="スプライトのキャンバスサイズ")
    parser.add_argument("--body", type=int, default=30, help="キャラ本体の最大の縦横ピクセル数")
    parser.add_argument("--colors", type=int, default=16)
    parser.add_argument("--tolerance", type=float, default=100.0, help="背景色とみなす色の距離（縁のにじみが残る場合は上げる）")
    parser.add_argument("--min-area", type=int, default=200, help="これより小さい成分はノイズとして無視")
    parser.add_argument("--preview-scale", type=int, default=6)
    args = parser.parse_args()

    names = [n.strip() for n in args.names.split(",") if n.strip()]
    image = Image.open(args.input).convert("RGBA")
    rgb = np.array(image)[:, :, :3]
    fg = ~background_mask(rgb, args.tolerance)

    boxes = find_characters(fg, args.min_area)
    if len(boxes) != len(names):
        raise SystemExit(f"キャラを {len(boxes)} 体検出しましたが、--names は {len(names)} 件です: {boxes}")

    args.out.mkdir(parents=True, exist_ok=True)
    rgba = np.array(image)
    rgba[~fg] = TRANSPARENT
    cleaned = Image.fromarray(rgba)

    frames_by_name = {}
    for name, box in zip(names, boxes):
        sprite = to_sprite(cleaned.crop(box), args.size, args.body, args.colors)
        frames = walk_frames(sprite)
        for i, frame in enumerate(frames):
            frame.save(args.out / f"{name}_right_{i}.png")
        frames_by_name[name] = frames
        print(f"{name}: box={box} -> {args.out}/{name}_right_0..3.png")

    preview(frames_by_name, args.out, args.preview_scale)
    print(f"preview: {args.out}/preview_sheet.png, {args.out}/preview_walk.gif")


if __name__ == "__main__":
    main()
